package com.toyoda.map_memo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.flutter_map_memo/folder"
        private const val PICK_DIRECTORY_REQUEST = 7001
    }

    private var pendingDirectoryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handleMethodCall(call, result) }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(result)
            "directoryExists" -> result.success(rootDirectory(call)?.exists() == true)
            "listEntries" -> result.success(directoryEntries(call))
            "readFile" -> result.success(readFile(call))
            "writeFile" -> writeFile(call, result)
            "deleteFile" -> deleteFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingDirectoryResult != null) {
            result.error("already_active", "フォルダ選択はすでに表示中です", null)
            return
        }
        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
        }
        startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_DIRECTORY_REQUEST) return
        val result = pendingDirectoryResult ?: return
        pendingDirectoryResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        val grantedFlags = (data?.flags ?: 0) and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            contentResolver.takePersistableUriPermission(uri, grantedFlags)
            result.success(uri.toString())
        } catch (error: SecurityException) {
            result.error("permission_error", "フォルダへの永続アクセス権を保存できませんでした", error.message)
        }
    }

    private fun rootDirectory(call: MethodCall): DocumentFile? {
        val rootUri = call.argument<String>("rootUri") ?: return null
        return DocumentFile.fromTreeUri(this, Uri.parse(rootUri))
    }

    private fun relativePath(call: MethodCall): String =
        call.argument<String>("relativePath")?.trim('/') ?: ""

    private fun resolveDirectory(root: DocumentFile, path: String, create: Boolean): DocumentFile? {
        var current = root
        for (part in path.split('/').filter { it.isNotBlank() }) {
            val existing = current.findFile(part)
            current = when {
                existing?.isDirectory == true -> existing
                existing == null && create -> current.createDirectory(part) ?: return null
                else -> return null
            }
        }
        return current
    }

    private fun directoryEntries(call: MethodCall): List<Map<String, Any>> {
        val root = rootDirectory(call) ?: return emptyList()
        val directory = resolveDirectory(root, relativePath(call), false) ?: return emptyList()
        return directory.listFiles().mapNotNull { file ->
            file.name?.let { name -> mapOf("name" to name, "isDirectory" to file.isDirectory) }
        }
    }

    private fun readFile(call: MethodCall): String? {
        val root = rootDirectory(call) ?: return null
        val parts = relativePath(call).split('/').filter { it.isNotBlank() }
        if (parts.isEmpty()) return null
        val parent = resolveDirectory(root, parts.dropLast(1).joinToString("/"), false) ?: return null
        val file = parent.findFile(parts.last()) ?: return null
        return contentResolver.openInputStream(file.uri)?.bufferedReader()?.use { it.readText() }
    }

    private fun writeFile(call: MethodCall, result: MethodChannel.Result) {
        val root = rootDirectory(call)
        val content = call.argument<String>("content")
        val parts = relativePath(call).split('/').filter { it.isNotBlank() }
        if (root == null || content == null || parts.isEmpty()) {
            result.error("invalid_arguments", "保存先または内容が不正です", null)
            return
        }
        try {
            val parent = resolveDirectory(root, parts.dropLast(1).joinToString("/"), true)
            if (parent == null) {
                result.error("directory_error", "保存先フォルダを作成できませんでした", null)
                return
            }
            val file = parent.findFile(parts.last())
                ?: parent.createFile("application/json", parts.last())
            if (file == null) {
                result.error("file_error", "保存ファイルを作成できませんでした", null)
                return
            }
            val outputStream = contentResolver.openOutputStream(file.uri, "wt")
                ?: throw IOException("出力ストリームを開けませんでした")
            outputStream.bufferedWriter().use { it.write(content) }
            result.success(null)
        } catch (error: Exception) {
            result.error("write_error", "ファイルを保存できませんでした", error.message)
        }
    }

    private fun deleteFile(call: MethodCall, result: MethodChannel.Result) {
        val root = rootDirectory(call)
        val parts = relativePath(call).split('/').filter { it.isNotBlank() }
        if (root == null || parts.isEmpty()) {
            result.error("invalid_arguments", "削除先が不正です", null)
            return
        }
        val parent = resolveDirectory(root, parts.dropLast(1).joinToString("/"), false)
        val file = parent?.findFile(parts.last())
        if (file == null) {
            result.success(null)
            return
        }
        if (!file.delete()) {
            result.error("delete_error", "ファイルを削除できませんでした", null)
            return
        }
        result.success(null)
    }
}
