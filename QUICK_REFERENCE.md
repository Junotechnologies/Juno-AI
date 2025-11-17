# 🚀 Quick Reference: VS Code + Vertex AI Workbench

## 🔗 Connect to Your Instance
```
VS Code → Cmd+Shift+P → "Remote-SSH: Connect to Host" → vertex-workbench
```

## 📁 Access Your Files
```
Open Folder → /home/jupyter
```

## 📓 Run Jupyter Notebooks
1. Open `.ipynb` file
2. Select Python kernel (Python 3.10.18)
3. Run cells: `Shift+Enter`

## 🐍 Run Python Scripts
- **Entire file**: `F5`
- **Selected code**: `Shift+Enter`
- **Interactive**: `Ctrl+Shift+P` → "Python: Start REPL"

## ⌨️ Essential Keyboard Shortcuts
- **Command Palette**: `Ctrl+Shift+P` (or `Cmd+Shift+P`)
- **Quick File Open**: `Ctrl+P`
- **Terminal**: `Ctrl+`` (backtick)
- **Run Cell**: `Shift+Enter`
- **Run File**: `F5`
- **Debug**: `F9` (breakpoint), `F5` (start debug)

## 🛠️ Must-Have Extensions
Install these on your remote connection:
- **Python** (Microsoft)
- **Jupyter** (Microsoft)
- **Pylance** (Microsoft)
- **GitHub Copilot** (optional, but amazing!)

## 🔄 After Instance Restart
```bash
./update-ssh-ip.sh
```
Then reconnect VS Code to vertex-workbench

## 📍 File Locations
- **Your files**: `/home/jupyter/`
- **Notebooks**: `/home/jupyter/*.ipynb`
- **Python scripts**: `/home/jupyter/*.py`
- **Data**: `/home/jupyter/data/` (if exists)

## 🎯 Common Tasks
- **Install packages**: Open terminal → `pip install package-name`
- **Check Python version**: `python --version`
- **List files**: `ls -la`
- **Find notebooks**: `find . -name "*.ipynb"`

## 🚀 Why This is Better Than JupyterLab
- ✅ **No browser lag** - Native desktop app
- ✅ **Superior debugging** - Breakpoints, variable inspection
- ✅ **Better autocomplete** - IntelliSense that works
- ✅ **Multi-file projects** - Work on entire codebases
- ✅ **Git integration** - Visual version control
- ✅ **Themes & customization** - Dark mode, fonts, layouts
- ✅ **50,000+ extensions** - Tools for everything

---
**Your JupyterLab files now have VS Code superpowers! 🚀**
