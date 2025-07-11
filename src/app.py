import app
import os
from config import Config

app = app.get_app()

if __name__ == "__main__":
    config = Config()
    os.environ["GOOGLE_API_KEY"] = config.get('googleApiKey')
    app.run(host="0.0.0.0", port=8080, debug=True)
