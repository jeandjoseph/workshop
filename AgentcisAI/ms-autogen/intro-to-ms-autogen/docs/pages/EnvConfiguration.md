## 🛠️ Getting Your Environment Ready

🧰 Before diving into the workshop, let’s set up your Python environment and install the required libraries.

🧑‍💻 **Prerequisite:** 
1. Make sure you have [Visual Studio Code (VS Code)](https://code.visualstudio.com/download) or any similar IDE and [Python](https://www.python.org/downloads/) installed before proceeding with the virtual environment setup.
    * If the link doesn’t work, you can download VS Code here: https://code.visualstudio.com/download and https://www.python.org/downloads/

2. You need an Azure OpenAI or OpenAI subscription to deploy one or more types of generative AI models. Alternatively, you’re free to download a model locally if you prefer managing it yourself.

    - For the Microsoft Azure platform, please follow these instructions:
        1. Sign up for a [free subscription](https://azure.microsoft.com/en-us/) or use your existing Azure subscription.
        2. Create an [AI Foundry](https://ai.azure.com/) workspace to manage and host your models.
        3. Deploy a model of your choice.  
            - For this workshop, we’re using **gpt-4.1-nano** to optimize for cost.
            - You can browse other models in the AI Foundry interface based on your needs.
        4. Copy, and paste the following details into a plain text file:
            - API endpoint URL
            - API key
            - Model version
        5. Create a new folder (for instance, name it `AIAgent`) to keep your project structure clean and secure.
        6. Save the text file as **.env** (environment configuration file) inside the newly created folder.
---

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

🌟 Proceed to the **Next Page** to dive into the core concepts of [Microsoft Autogen](https://microsoft.github.io/autogen/stable/index.html)


<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/autogencomponents.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/DirectHumanInteraction.md">Next → Page</a>
    </td>
  </tr>
</table>
