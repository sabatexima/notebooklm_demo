# 必要なライブラリをインポート
import os
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.schema import (
    AIMessage,
    HumanMessage,
    SystemMessage
)
import json

# チャット機能を提供するクラス
class chat:

    # モデルを安全に呼び出す
    # モデルの呼び出し中にエラーが発生しても、プログラムが停止しないようにします。
    def safe_invoke(self, model, messages):
        try:
            response = model.invoke(messages)
            return response
        except Exception as e:
            return {"error": str(e)}

    # LLMモデルを設定
    # 使用する大規模言語モデル（LLM）のインスタンスを生成します。
    def setLlm(self, name):
        llm = ChatGoogleGenerativeAI(
            model=name,
            temperature=0,
            max_tokens=None,
            timeout=None,
            max_retries=2,
        )
        return llm

    # チャットを実行
    # ユーザーからのテキストメッセージを受け取り、AIの応答を生成します。
    def chat(self, chatlog):
        llm = self.setLlm("gemini-2.5-pro")

        # メッセージを作成
        # システムメッセージとしてキャラクター情報、人間からのメッセージとしてユーザーのテキストを設定します。
        messages = [
            SystemMessage(content="以下のチャットのやりとりをもとに、ユーザーの心理的特徴（性格、感情傾向、開示度など）を推定し、それに対する生成AIの応答がどれだけ心理的に適応しているかを100点満点で評価してください。"),
            HumanMessage(content=chatlog)
        ]

        response = self.safe_invoke(llm, messages)
        chat_con = response.content
        print(chat_con)
        return chat_con