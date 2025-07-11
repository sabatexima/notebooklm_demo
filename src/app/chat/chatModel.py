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
    def __init__(self,name):
        # 設定ファイルを読み込む
        self.chara = self.setChara(name)
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

    # キャラクターを設定
    # chara.jsonファイルからキャラクターの情報を読み込みます。
    def setChara(self, name):
        with open("app/chat/chara.json", "r", encoding="utf-8") as file:
            chara_data = json.load(file)
        user = chara_data.get(name, {}) 
        return user

    # チャットを実行
    # ユーザーからのテキストメッセージを受け取り、AIの応答を生成します。
    def chat(self, text,setting):
        llm = self.setLlm("gemini-2.5-flash")

        # メッセージを作成
        # システムメッセージとしてキャラクター情報、人間からのメッセージとしてユーザーのテキストを設定します。
        messages = [
            SystemMessage(content=json.dumps(self.chara, ensure_ascii=False) + ",前提知識：" +setting),
            HumanMessage(content=text)
        ]

        response = self.safe_invoke(llm, messages)
        chat_con = response.content
        return chat_con