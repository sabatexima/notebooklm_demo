import json
import os


class Config:
    
    def __init__(self, filepath: str='config.json'):
        self.filepath = filepath
        self.data = {}
        
        self.load()
    
    
    def load(self):
        """
        設定ファイルを読み込む
        """
        
        if os.path.isfile(self.filepath):
            with open(self.filepath, 'r') as f:
                self.data = json.load(f)
        else:
            self.load_default()
            self.save()
    
    
    def save(self):
        """
        設定ファイルを保存する
        """
        
        with open(self.filepath, 'w') as f:
            json.dump(self.data, f, ensure_ascii=False, indent=4, sort_keys=True, separators=(',', ': '))
            os.chmod(self.filepath, 0o777)
    
    
    def get(self, key: str):
        """
        設定を取得
        
        Args:
            key(str): 設定キー
        """
        
        keys = key.split('.')
        value = self.data
        
        for k in keys:
            if k in value:
                value = value[k]
        
        return value
    
    
    def load_default(self):
        """
        デフォルト設定を読み込む
        """
        
        with open('default_config.json', 'r') as f:
            self.data = json.load(f)