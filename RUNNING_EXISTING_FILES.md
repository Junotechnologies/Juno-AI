# 🚀 Running Your Existing JupyterLab Files in VS Code

Now that VS Code is connected to your Vertex AI Workbench instance, you can access and run all your existing JupyterLab files directly in VS Code with superior features!

## 📁 Accessing Your Files

### Step 1: Connect to VS Code
1. Open VS Code
2. Press `Cmd+Shift+P` (or `Ctrl+Shift+P`)
3. Type: `Remote-SSH: Connect to Host`
4. Select: `vertex-workbench`

### Step 2: Open Your Working Directory
1. Once connected, click **"Open Folder"**
2. Navigate to: `/home/jupyter`
3. This is where all your JupyterLab files are stored

## 📓 Running Jupyter Notebooks (.ipynb files)

### First Time Setup
1. **Install Jupyter Extension** (if not already installed):
   - Go to Extensions tab in VS Code
   - Search for "Jupyter" by Microsoft
   - Click "Install in SSH: vertex-workbench"

2. **Install Python Extension**:
   - Search for "Python" by Microsoft
   - Click "Install in SSH: vertex-workbench"

### Running Notebooks
1. **Open any `.ipynb` file** from your file explorer
2. **Select Python Kernel**:
   - Click "Select Kernel" at top right
   - Choose: `Python 3.10.18` (or the conda environment you prefer)
3. **Run cells**:
   - Click ▶️ button next to each cell
   - Or press `Shift+Enter` to run current cell
   - Or press `Ctrl+Enter` to run cell without moving to next

### 🎯 VS Code Notebook Advantages
- **Better IntelliSense**: Superior code completion
- **Debugging**: Set breakpoints in notebook cells
- **Variable Inspector**: See all variables in the sidebar
- **Outline View**: Navigate large notebooks easily
- **Git Integration**: Track notebook changes visually

## 🐍 Running Python Scripts (.py files)

### Method 1: Run Entire Script
1. Open any `.py` file
2. Press `F5` or click "Run Python File" button
3. Output appears in integrated terminal

### Method 2: Run Selected Code
1. Select code you want to run
2. Press `Shift+Enter` to run selection in terminal
3. Great for testing code snippets

### Method 3: Interactive Python
1. Press `Ctrl+Shift+P`
2. Type: `Python: Start REPL`
3. Interactive Python session in terminal

## 🔍 Finding Your Files

### Common File Locations
```bash
/home/jupyter/                    # Your home directory
├── notebooks/                   # Jupyter notebooks (if any)
├── *.ipynb                      # Individual notebook files
├── *.py                         # Python scripts
├── data/                        # Data files
└── projects/                    # Project folders
```

### Search for Files
1. **In VS Code**: Press `Ctrl+P` and type filename
2. **In Terminal**: Use `find /home/jupyter -name "*.ipynb"`

## 🛠️ Working with Different File Types

### Jupyter Notebooks (.ipynb)
- ✅ **Full notebook support** with cell execution
- ✅ **Rich output** including plots, HTML, markdown
- ✅ **Debugging** with breakpoints
- ✅ **Variable inspector**

### Python Scripts (.py)
- ✅ **Full debugging** with breakpoints
- ✅ **IntelliSense** and code completion
- ✅ **Linting** and error detection
- ✅ **Refactoring** tools

### Data Files (.csv, .json, etc.)
- ✅ **Preview** data files directly
- ✅ **CSV viewer** for spreadsheet-like view
- ✅ **JSON formatter** for structured data

## 🚀 Enhanced Workflow Tips

### 1. Use Integrated Terminal
- Press `Ctrl+`` (backtick) to open terminal
- Run commands directly on your instance
- Install packages: `pip install package-name`

### 2. Multi-file Projects
- Open entire project folders
- Navigate between files easily
- Use file explorer sidebar

### 3. Git Integration
- Initialize git: `git init`
- Stage changes visually
- Commit with descriptive messages

### 4. Extensions to Install
- **GitHub Copilot** - AI coding assistant
- **Pylance** - Advanced Python language server
- **autoDocstring** - Generate docstrings
- **Black Formatter** - Code formatting

## 🔄 Migrating from JupyterLab Workflow

### What Stays the Same
- ✅ All your files are in the same location
- ✅ Same Python environment and packages
- ✅ Same computational resources
- ✅ Same data and model files

### What Gets Better
- 🚀 **Faster interface** - No browser lag
- 🚀 **Better debugging** - Set breakpoints anywhere
- 🚀 **Superior autocomplete** - IntelliSense that actually works
- 🚀 **Multi-file editing** - Work on entire projects
- 🚀 **Git integration** - Version control made easy
- 🚀 **Themes** - Dark mode and customization
- 🚀 **Extensions** - 50,000+ tools available

## 🎯 Quick Start Checklist

1. ✅ Connect VS Code to `vertex-workbench`
2. ✅ Open folder: `/home/jupyter`
3. ✅ Install Python + Jupyter extensions
4. ✅ Open your first `.ipynb` file
5. ✅ Select Python kernel
6. ✅ Run your first cell with `Shift+Enter`
7. ✅ Enjoy the superior VS Code experience!

## 💡 Pro Tips

- **Keyboard shortcuts**: Learn VS Code shortcuts for faster workflow
- **Command palette**: `Ctrl+Shift+P` for any action
- **Quick file open**: `Ctrl+P` to quickly open files
- **Split editor**: Work on multiple files side by side
- **Zen mode**: `Ctrl+K Z` for distraction-free coding

Your existing JupyterLab files now have superpowers with VS Code! 🚀
