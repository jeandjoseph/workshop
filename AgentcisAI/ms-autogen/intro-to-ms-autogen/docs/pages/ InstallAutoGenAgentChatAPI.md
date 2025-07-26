## ⚙️ Installing Microsoft AutoGen AgentChat DSK for Azure OpenAI API
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

pip install aioodbc
pip install pandas
pip install Seaborn
pip install Matplotlib

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

🔙 Return to the [Getting Your Environment Ready](../pages/GettingEnvReady.md) or click on [Install Microsoft Autogen Studion]() to continue working with Microsoft AutoGen Studio.
