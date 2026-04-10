from src.app.dashboard import build_app


app = build_app()
server = app.server


if __name__ == "__main__":
    app.run(debug=True)
