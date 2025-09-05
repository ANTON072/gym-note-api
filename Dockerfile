FROM ruby:3.4.5

# 必要なパッケージをインストール（MariaDBクライアント含む）
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libmariadb-dev \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app

# GemfileとGemfile.lockをコピー
COPY Gemfile Gemfile.lock ./

# bundlerをインストール
RUN gem install bundler -v 2.4.10

# gemをインストール
RUN bundle install

# アプリケーションのコードをコピー
COPY . .

# ポート3000を公開
EXPOSE 3000

# サーバー起動
CMD ["rails", "server", "-b", "0.0.0.0"]
