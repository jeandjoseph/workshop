## ⚙️ Installing Microsoft AutoGen AgentChat SDK for Azure OpenAI API
The **AgentChat SDK** is a high-level Python API within [Microsoft AutoGen](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/installation.html) designed for building and orchestrating multi-agent AI systems. It simplifies the creation of agents that can communicate, collaborate, and execute tasks autonomously.

#### 🔧 Key Features
- **Preset agent behaviors** for rapid prototyping
- **Team orchestration patterns** like round-robin, selector, and swarm
- **Message-passing architecture** for agent communication
- **Tool integration** for code execution, web browsing, and more
- **Custom agent support** via subclassing `BaseChatAgent`


#### 📦 Step 1: Install Required Dependencies for Microsoft AutoGen AgentChat SDK

- 🧠 Ensure your [virtual environment](../pages/CreatePythonVirtualEnv.md) is **active** before proceeding.
- Paste the following commands into your terminal to install core libraries and extensions:

```bash
pip install "autogen-agentchat" "autogen-ext[openai,azure]"  # Agent orchestration + provider integration
pip install python-dotenv                                    # For managing environment variables securely
pip install nest_asyncio                                     # Enables async compatibility in notebooks

pip install tiktoken                                         # Token encoding for LLM compatibility
pip install streamlit                                        # Optional: UI framework for interactive demos

pip install aioodbc                                          # Async ODBC driver for accessing databases in agentic workflows
pip install pandas                                           # Core data manipulation library; essential for tabular data operations
pip install Seaborn                                          # High-level statistical data visualization built on top of Matplotlib
pip install Matplotlib                                       # Foundational plotting library for generating figures and charts


```

⏳ Sit back while the packages install—you’re laying the foundation for agent workflows, environment config, and UI demos!

💡 These dependencies enable agent orchestration, async event handling, OpenAI/Azure integration, and front-end capabilities via Streamlit.

#### ✅ Step 2: Validate Your Python Environment Setup

- 🔍 Run the following commands in your terminal to confirm that key packages are correctly installed:
```bash
pip show autogen-agentchat
pip show autogen-ext
pip show openai
```

📋 Each command should return detailed info about the package if installation was successful (e.g., name, version, license, location).

🚀 If no errors appear and the output looks similar to the sample below, you’re good to go for the hands-on workshop!

![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/pip_show_if_library_installed.png)

💡 Pro tip: Save your terminal output as part of a session log if you're documenting setup reproducibility.

🔙 **Return to** [Getting Your Environment Ready](../pages/GettingEnvReady.md) If your environment is not fully configured, .

Otherwise, click on the **Next Page** to begin our first hands-on activity where a human collaborator will interact directly with the AI agent.

<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/InstallAutogenStudio.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/DirectHumanInteraction.md">Next Page →</a>
    </td>
  </tr>
</table>
