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


🖥️ To set up your environment, simply copy and paste the codes into your terminal, whether you're using VS Code, CMD/Shell, or any other IDE.


#### 🐍 1. Create a Python Virtual Environment
```bash
python -m venv autogenv5
```

#### ⚡ 2. Activate Your Python Virtual Environment
 - For PowerShell on Windows
 - Or use the appropriate activation command for your OS/shell
 - Step to follow:
   - Navigate to your **Python Virtual Environment** folder.
   - Expand the environment directory to reveal subfolders.
   - Open the **Scripts** folder inside the environment.
   - Right-click on `Activate.ps1`.
   - Select **Copy Path** from the context menu.
     ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/right_click_copy_path_activate_py_env.png)
   - Open your **terminal or PowerShell window**.
   - Paste the copied path directly into the terminal to activate the environment:
     ```powershell
     & "F:/DevDemos/DataAnalysis/autogenv5/Scripts/Activate.ps1"
   - You should see a screen similar to the one shown below.

     ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/ps_script_activate_py_env.png)
   - Press **Enter** and wait until the exexution is done
   - Again, You should see a screen similar to the one shown below, with the relevant section highlighted in red. If this appears, you're all set to begin installing the dependencies.
     ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/pyenv.png)


### 📦 3. Install Dependencies
Paste these commands into the virtual Python environment you've just activated, then sit back while the installation completes.
```bash
pip install "autogen-agentchat" "autogen-ext[openai,azure]"
pip install python-dotenv
pip install nest_asyncio
pip install tiktoken

pip install streamlit
```
Run the following commands to validate your environment for the workshop: `pip show autogen-agentchat`, `pip show autogen-ext`, and `pip show openai`. If no errors appear on your screen, then you're all set to go! 🚀
```bash
pip show autogen-agentchat
pip show autogen-ext
pip show openai
```

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
