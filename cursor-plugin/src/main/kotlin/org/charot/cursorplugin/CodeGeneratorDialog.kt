package org.charot.cursorplugin

import com.intellij.openapi.ui.DialogWrapper
import com.intellij.openapi.ui.Messages
import com.intellij.ui.components.JBTextField
import javax.swing.BoxLayout
import javax.swing.JComponent
import javax.swing.JLabel
import javax.swing.JPanel
import kotlin.properties.Delegates

class CodeGeneratorDialog(private val service: CodeGeneratorService) : DialogWrapper(true) {
    private val descriptionField: JBTextField = JBTextField()
    private var generatedCode: String by Delegates.notNull()

    init {
        title = "Генерация кода"
        init() // Инициализация диалога
    }

    override fun createCenterPanel(): JComponent? {
        val panel = JPanel()
        panel.layout = BoxLayout(panel, BoxLayout.Y_AXIS)

        panel.add(JLabel("Введите описание:"))
        panel.add(descriptionField)

        return panel
    }

    override fun doOKAction() {
        val description = descriptionField.text
        generatedCode = service.generateCode(description)
        Messages.showMessageDialog(generatedCode, "Сгенерированный код", Messages.getInformationIcon())
        super.doOKAction() // Закрытие диалога
    }
}