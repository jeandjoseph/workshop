## ⚙️ Installing Microsoft AutoGen for Azure OpenAI API

#### 🐍 Step 1: Set Up Your Python Virtual Environment

- Create a new folder named **AIAgent**.
- Launch **VS Code** or any IDE you're comfortable using.
- Ensure your terminal’s working directory is set to the newly created `AIAgent` folder.
- Run the following command in the terminal to create a virtual environment named `autogenv5`:
  ```bash
  python -m venv autogenv5
  ```

#### ⚡ Step 2: Activate Your Python Virtual Environment
   - 💻 For **PowerShell on Windows** (other OS/shells may require a different command).
   - Navigate to your **Python Virtual Environment** folder.
   - Expand the environment directory to reveal its subfolders.
   - Open the **Scripts** folder inside the environment.
   - Right-click on `Activate.ps1`.
   - Select **Copy Path** from the context menu.
     ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/right_click_copy_path_activate_py_env.png)
   - Open your terminal (PowerShell).
   - Paste the copied path directly into the terminal to activate the environment:
     ```powershell
     & "F:/DevDemos/DataAnalysis/autogenv5/Scripts/Activate.ps1"
   - You should see a screen similar to the one shown below.

     ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/ps_script_activate_py_env.png)
   - Press **Enter** and wait until the exexution is done
   - Again, You should see a screen similar to the one shown below, with the relevant section highlighted in red. If this appears, you're all set to begin installing the dependencies.
     ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/pyenv.png)
