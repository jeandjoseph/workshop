#
<h1 style="color:white; text-align:center;">
Microsoft AutoGen Multi-Agent: <br>
Dynamic Multi-Turn Conversation Control Chatbot
</h1>
In this Microsoft AutoGen workshop, we’re building a chatbot app with Streamlit, where three AI agents communicate behind the scenes and you get to watch their conversation unfold live. Streamlit, an open-source Python framework, makes it easy to create interactive web apps without any frontend code. It’s the perfect tool to visualize how agents collaborate, debate, and solve tasks together in real time.

<br>

To make the experience even more natural, each topic in the chatbot app has its own conversation thread—just like a real debate. Agents take turns responding, exchange perspectives, and then the chat resets for the next topic, giving every discussion a clear start and finish.

<br>

## 🚀 What to Expect from This Demo

You’ll explore a chatbot app powered by Streamlit, where **three AI agents** engage in real-time, debate-style conversations. Each topic starts a fresh thread, and the agents take turns sharing insights, questioning each other, and collaboratively working through the subject—just like a human panel.

### 💡 Key Features
- Watch agent-to-agent discussions unfold live
- Topic-specific chat resets for clarity
- Seamless transitions between debate sessions

---

### 🛠️ Try It Yourself

1. **Copy** the provided script into a plain text editor (like Notepad).
2. **Save it** as `autogen_chatbot_app.py`.
```bash
import os, sys
import asyncio
from dotenv import load_dotenv

# 🤖 AgentChat and Azure OpenAI imports
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.base import TaskResult

# 🌱 Load environment variables from .env file
load_dotenv()

# 🔐 Retrieve Azure OpenAI credentials from environment
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

# 🚨 Windows compatibility for asyncio event loop
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

# 🧠 Setup debate team with agents and moderator
async def initialize_ai_debate_team(subject):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    Jean = AssistantAgent(
        name="Jean",
        model_client=model_client,
        system_message=(
            f"You are Jean, a Data Engineer. Your task is to clearly and concisely explain the importance of {subject}. "
            "Introduce yourself only at the start of the first conversation."
        ),
    )

    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            f"You are Daniel, an AI Engineer. Focus on {subject} with emphasis on data cleansing and feature engineering. "
            "Introduce yourself only at the start of the first conversation."
        ),
    )

    Moderator = AssistantAgent(
        name='Moderator',
        model_client=model_client,
        system_message=(
            f"You are Garellard, the moderator of the debate between Jean and Daniel. Subject: {subject}. "
            "Announce each round, flag round 3 as final, and end with 'TERMINATE'."
        )
    )

    return RoundRobinGroupChat(
        participants=[Moderator, Daniel, Jean],
        max_turns=15,
        termination_condition=TextMentionTermination(text="TERMINATE")
    )

# 📡 Run debate stream and update UI with messages
async def run_debate_and_stream(team):
    import streamlit as st  # ✅ Move import here before usage
    message_container = st.empty()
    content_buffer = []

    async for message in team.run_stream(task="Start the debate!"):
        if isinstance(message, TaskResult):
            formatted = f"🛑 **Stopping reason**: {message.stop_reason}"
        else:
            formatted = f"**{message.source}**: {message.content}"
        content_buffer.append(formatted)
        message_container.markdown("\n\n".join(content_buffer))

# 🖼️ Streamlit UI components (imported right before use)
import streamlit as st  # ✅ Primary import for Streamlit interface
st.set_page_config(page_title="AI Debate Arena", layout="wide")
st.title("🧠💬 AI Debate Arena")

# 📝 Capture user input for debate topic
topic = st.text_input("Enter debate topic:", value="type any kind of topics")
start_button = st.button("Start Debate")

# ⚙️ Initialize Streamlit session state
if "messages" not in st.session_state:
    st.session_state.messages = []
if "debate_triggered" not in st.session_state:
    st.session_state.debate_triggered = False

# ▶️ Start debate if triggered
if start_button and topic and not st.session_state.debate_triggered:
    async def debate_sequence():
        team = await initialize_ai_debate_team(topic)
        await run_debate_and_stream(team)

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(debate_sequence())

# 💬 Display message history after debate
st.markdown("---")
for msg in st.session_state.messages:
    st.markdown(msg)
```

3. **Open your terminal**, then run:
```bash
   streamlit run autogen_chatbot_app.py
```

4. 🌐 Once the Streamlit App Opens in Your Browser, Follow These Steps:
    1. Go to the local Streamlit URL-usually `http://localhost:8502/`.
    2. Find the input box labeled **Enter debate topic**.
    3. Type in a topic of your choice, such as `Data Cleansing`.
    4. Click the **Start Debating** button.
    5. Observe the live debate unfold between three AI agents as they take turns discussing the topic.


### 🔄 Switching Chat Modes

To explore a different chat strategy, click on **Next Page**. This will change the context from `RoundRobinGroupChat` to `SelectOneGroupChat`, allowing a single agent to lead the response while others observe-perfect for spotlight-style interactions.


<div style="display: flex; justify-content: space-between;">
  <a href="DirectAgentInteractionMultiTurnDynamicTermination.md">← Previous Page</a>
  <a href="DirectAgentDynamicInteractionSelect.md">Next → Page</a>
</div>