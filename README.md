# Teyca Test Task

Небольшое Sinatra + Sequel приложение для расчёта и подтверждения операций лояльности.

## Требования

- Ruby `~> 3.4` (зафиксировано в `.ruby-version` как `3.4.1`)
- Bundler

## Установка

```bash
bundle install
```

## База данных

Схема описана кодом в `db/migrations`, начальные данные — в `db/seeds.rb`.
БД (SQLite-файл `test.db`) не хранится в репозитории и собирается из миграций:

```bash
bundle exec rake db:setup     # migrate + seed «с нуля»
# либо по шагам:
bundle exec rake db:migrate
bundle exec rake db:seed
```

Путь к файлу можно переопределить через `TEYCA_DB_PATH`.

## Запуск приложения

```bash
bundle exec rackup            # поднимет config.ru на Puma
```

## Тесты

```bash
bundle exec rake spec         # или: bundle exec rspec
```
