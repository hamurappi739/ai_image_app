# Стратегия промптов фотосессии

Как backend собирает инструкции для **3 отдельных кадров** одной фотосессии.

Связанные документы: [catalog_management.md](catalog_management.md), [api_contract.md](api_contract.md), [preview_generation_prompts.md](preview_generation_prompts.md).

---

## Идея

Фотосессия — это **не один коллаж**, а **3 отдельных изображения** в одном стиле.

Для каждого кадра backend формирует финальный prompt:

1. **base prompt** — общий стиль (`prompt` из каталога или `description` для «Своей фотосессии»)
2. **identity lock** — сохранить лицо и единство серии (локация, свет, одежда)
3. **frame prompt** — ракурс и поза конкретного кадра (`framePrompts[0..2]`)
4. **negative quality** — запрет текста, коллажа, искажений
5. **single-image rules** (English) — техническое правило «ровно одно изображение» для Gemini

Код: `backend/app/services/photoshoot_prompts.py` → `build_photoshoot_frame_prompt()`.

---

## Каталог

В `backend/app/catalog/photoshoots.json` (и зеркале `frontend/assets/catalog/photoshoots.json`):

```json
{
  "id": "business_portrait",
  "prompt": "общий стиль серии...",
  "framePrompts": [
    "кадр 1...",
    "кадр 2...",
    "кадр 3..."
  ]
}
```

`GET /catalog/photoshoots` отдаёт `framePrompts` в API (frontend может игнорировать).

---

## Выбор frame prompt при генерации

`POST /photoshoots/generate`:

1. По `style_id` из формы ищется запись в каталоге (`get_photoshoot_catalog_item`).
2. Если есть `framePrompts` (3 строки) — используются для кадров 1–3.
3. Если `framePrompts` нет — fallback из `FRAME_PROMPTS_BY_STYLE_ID` в коде, затем generic:
   - «Кадр 1 из 3: основной портрет…»
   - «Кадр 2 из 3: лёгкий поворот…»
   - «Кадр 3 из 3: чуть шире…»
4. **Своя фотосессия** (`description` в форме): `description` = base prompt, frame = generic fallback.

Для **каждого** кадра Gemini вызывается **отдельно** с своим frame prompt. Mock provider по-прежнему возвращает 3 placeholder URL без промптов.

---

## Ожидания и ограничения

- Цель: **3 фото в одном стиле**, а не абсолютная студийная идентичность пиксель-в-пиксель.
- Gemini может слегка отличать локацию или оттенок одежды; новая структура **уменьшает рассинхрон**, но не гарантирует 100% совпадение.
- Мы **не** просим модель вернуть 3 кадра на одном холсте.
- Обычная генерация (`POST /generate`, `/generate-with-photo`) и шаблоны **не используют** identity lock фотосессии.

---

## Редактирование

1. Обновить `framePrompts` в `backend/app/catalog/photoshoots.json`.
2. Скопировать в `frontend/assets/catalog/photoshoots.json` (или синхронизировать скриптом).
3. Перезапустить backend — каталог читается при первом обращении (кэш сбрасывается при рестарте процесса).
