package org.charot.cursorplugin

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.components.service

class GenerateCodeAction : AnAction("Генерация кода") {
    override fun actionPerformed(e: AnActionEvent) {
        val service = service<CodeGeneratorService>()
        val dialog = CodeGeneratorDialog(service)
        dialog.show() // Показать диалог
    }
}