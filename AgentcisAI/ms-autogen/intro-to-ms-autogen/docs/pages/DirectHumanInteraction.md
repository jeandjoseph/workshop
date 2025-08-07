# 🧑‍💻 Direct Human Interaction with Microsoft AutoGen

This demo showcases one of the cleanest ways to get started with Microsoft AutoGen: a human interacting directly with an AI agent, no orchestration layers, no multi-agent complexity. It’s a hands-on loop where your message becomes a structured signal, and the model responds like a conversational partner.

### 🧠 What’s Happening Behind the Scenes

You type a message. That message is wrapped in a `UserMessage` object and sent to an AI model via `AzureOpenAIChatCompletionClient`. The model replies, and you see the response just like chatting with an assistant. AutoGen handles the structure, so you don’t have to worry about formatting or protocol.

### 🤖 Why This Is Agentic

In AutoGen, an agent is anything that can send, receive, and act on messages. In this setup:

- **You** are the initiating agent  
- **The model** is the responding agent  
- **The script** is the bridge using AutoGen’s building blocks to make the exchange seamless

### 🛠️ How It Works

- Loads credentials from `.env`  
- Initializes the model client (`AzureOpenAIChatCompletionClient`)  
- Wraps your input in a `UserMessage` with `source="user"`  
- Sends it to the model and waits for a reply  
- Loops until you type `"done"`

### 🧩 Why It Matters

This pattern is perfect for:

- Prototyping agent behavior  
- Testing model responses in isolation  
- Embedding human-in-the-loop workflows


#### ⚙️ Steps to Run `HumanAndAIAgent.py`
1. 🛠️ Before you begin, make sure your [Python virtual environment](https://github.com/jeandjoseph/workshop/blob/main/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/pages/GettingEnvReady.md) is activated, all dependencies are installed, and your `.env` file is properly configured. Everything should be running smoothly before you proceed.

2. Copy & Paste the code below into a text editor. You can use something simple like Notepad.

```python
import os
from dotenv import load_dotenv
# Imports the Azure OpenAI Chat Completion Client from the autogen_ext.models.openai module
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
# Imports the UserMessage class from the autogen_core.models module
from autogen_core.models import UserMessage
# Asynchronously imports the asyncio module to handle asynchronous operations
import asyncio


# Load environment variables from .env file
load_dotenv()

# Retrieve environment variables
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# Print retrieved environment variables
print(azure_openai_endpoint)
print(azure_openai_model_name)
print(azure_openai_api_version)


# Define an async function to interact with the model client
async def interact_with_model(user_message):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    # Create a user message and get the response from the model client
    result = await model_client.create([
        UserMessage(content=user_message, source="user")
    ])

    # Asynchronously close the model client, releasing any resources it holds
    await model_client.close()
    print(result.content)

# Loop to get user input until "done" is typed
def main():
    while True:
        user_input = input("Enter your message (type 'done' to exit): ").strip()
        if user_input.lower() == "done":
            break
        asyncio.run(interact_with_model(user_input))

# Run the main loop
if __name__ == "__main__":
    main()

```

3. Save the file as `HumanAndAIAgent.py`. Choose a folder where your virtual environment can easily access it.
4. 📦 With your virtual environment active and everything set up, launch the script by opening a terminal and executing the command below:
```bash
 python HumanAndAIAgent.py
```

5. When prompted, type `What is Power BI?` and feel free to experiment with different prompts.

🧩 Explanation this piece of code

```python
result = await model_client.create([
    UserMessage(content=user_message, source="user")
])
```
🧠 This line sends the user's input to the model as a structured message and waits for the model's response.

- `UserMessage(...)`: Wraps the input with metadata (content + source)
- `model_client.create([...])`: Sends the message to the model
- `await`: Pauses execution until the model replies
- `result`: Stores the model's response
- **Note**: `AzureOpenAIChatCompletionClient`: Connects to Azure-hosted models and handles structured message exchange


➡️ Click on the **Next Page** to begin demonstrating how agents interact with one another. We'll focus on fixed-turn conversations.

<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/InstallAutoGenAgentChatAPI.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/AgentRoundRobinGroupChat.md">Next Page →</a>
    </td>
  </tr>
</table>



