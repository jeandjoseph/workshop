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

#### 📦 Step 3: Install Required Dependencies
   - 🧠 Make sure your **virtual environment is activated** before proceeding.
   - Copy and paste the following commands into your terminal:
     ```bash
     pip install "autogen-agentchat" "autogen-ext[openai,azure]"
     pip install python-dotenv
     pip install nest_asyncio
     
     pip install tiktoken
     pip install streamlit
     ```
⏳ Sit back while the packages install—you’re laying the foundation for agent workflows, environment config, and UI demos!

💡 These dependencies enable agent orchestration, async event handling, OpenAI/Azure integration, and front-end capabilities via Streamlit.

#### ✅ Step 4: Validate Your Python Environment Setup
   - Run the following commands in your terminal to verify required packages are installed:
     ```bash
     pip show autogen-agentchat
     pip show autogen-ext
     pip show openai
     ```
📋 Each command should return detailed info about the package if installation was successful (e.g., name, version, license, location).

🚀 If no errors appear and the output looks similar to the sample below, you’re good to go for the hands-on workshop!

![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/pip_show_if_library_installed.png)

💡 Pro tip: Save your terminal output as part of a session log if you're documenting setup reproducibility.

🔙 Return to the [Getting Your Environment Ready](../pages/GettingEnvReady.md) or click on [Install Microsoft Autogen Studion]() to continue working with Microsoft AutoGen Studio.
