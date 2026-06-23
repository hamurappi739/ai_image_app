# Cursor handoff: preview assets and prompts

Цель файла: собрать понятное ТЗ для Cursor по превью-картинкам и будущим промптам. Этот файл можно давать Cursor как источник контекста.

Важно:
- Не читать и не менять `backend/.env` и любые `.env` файлы.
- Не менять backend generation, payment, auth, gallery, Supabase logic.
- Не делать git commit/push без отдельной команды пользователя.
- Превью единичных шаблонов: горизонтальные JPG 16:9.
- Превью фотосессий: 3 горизонтальные JPG 16:9 на один стиль.
- Генерируемые пользователем итоговые фото могут быть вертикальными 3:4, но это не относится к preview assets.

## Папки

Единичные шаблоны:

```text
frontend/assets/previews/templates/
```

Фотосессии:

```text
frontend/assets/previews/photoshoots/
```

Файлы должны быть JPG, нормального качества, без текста, логотипов и водяных знаков.

## Уже готовится пользователем: единичные preview ideas

Эти картинки пользователь сделал или делает отдельно. До подтверждения финальной привязки Cursor не должен сам добавлять новые карточки в каталог.

| Идея | Рекомендуемое рабочее имя | Статус | Комментарий |
|---|---|---|---|
| вулканическая серая скала | `volcanic_gray_rock.jpg` | done by user | Новая/заменяемая идея. Нужна финальная привязка к template id. |
| у океана | `ocean_portrait.jpg` | done by user | Новая/заменяемая идея. Нужна финальная привязка к template id. |
| пляжный песок | `beach_sand_portrait.jpg` | done by user | Новая/заменяемая идея. Нужна финальная привязка к template id. |
| белое платье, желтое поле/луг | `white_dress_yellow_meadow.jpg` | done by user | Новая/заменяемая идея. Нужна финальная привязка к template id. |
| фото с кошкой | `woman_with_cat.jpg` | done by user | Если такой карточки нет в каталоге, не добавлять без отдельного решения. |

## Пока не готово: оставшиеся единичные preview ideas

| Идея | Возможный target asset | Комментарий |
|---|---|---|
| мама и ребенок, день рождения | `frontend/assets/previews/templates/child_photo.jpg` | Это существующий asset для карточки `photo_with_child`. |
| ребенок с цифрой возраста | TBD | Новая идея, может требовать отдельной карточки и catalog change. |
| ребенок + имя/возраст | TBD | Лучше не вшивать текст в изображение. Имя/возраст безопаснее накладывать UI-слоем. |
| ребенок сейчас + детское воспоминание | TBD | Может требовать multi-image flow, не просто preview. |
| девушка/женщина с шарами | `frontend/assets/previews/templates/holiday_look.jpg` | Это существующий asset для карточки `festive_look`. |

## Текущие template assets в каталоге

Если пользователь хочет просто заменить существующие карточки, использовать только эти пути:

| Template id | Preview asset |
|---|---|
| `beautiful_portrait` | `frontend/assets/previews/templates/beautiful_portrait.jpg` |
| `social_photo` | `frontend/assets/previews/templates/social_photo.jpg` |
| `winter_portrait` | `frontend/assets/previews/templates/winter_portrait.jpg` |
| `summer_portrait` | `frontend/assets/previews/templates/summer_portrait.jpg` |
| `tender_portrait` | `frontend/assets/previews/templates/gentle_portrait.jpg` |
| `vibrant_look` | `frontend/assets/previews/templates/bright_look.jpg` |
| `business_portrait` | `frontend/assets/previews/templates/business_portrait.jpg` |
| `resume_photo` | `frontend/assets/previews/templates/resume_photo.jpg` |
| `profile_photo` | `frontend/assets/previews/templates/profile_photo.jpg` |
| `expert_look` | `frontend/assets/previews/templates/expert_look.jpg` |
| `family_photo` | `frontend/assets/previews/templates/family_photo.jpg` |
| `photo_with_child` | `frontend/assets/previews/templates/child_photo.jpg` |
| `festive_look` | `frontend/assets/previews/templates/holiday_look.jpg` |
| `product_photo` | `frontend/assets/previews/templates/product_photo.jpg` |
| `clothing_photo` | `frontend/assets/previews/templates/clothes_photo.jpg` |
| `jewelry_photo` | `frontend/assets/previews/templates/jewelry_photo.jpg` |
| `interior_photo` | `frontend/assets/previews/templates/interior_photo.jpg` |

## Rules for Cursor when importing preview assets

1. Only copy/replace image files that the user explicitly provides.
2. Do not invent missing images.
3. Do not add new catalog cards unless the user explicitly says to add new templates.
4. If replacing an existing preview, keep the exact filename already used by catalog JSON.
5. If adding a new preview idea not in catalog, put it in a temporary staging folder or ask for mapping first.
6. After replacing assets, run:

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter analyze
```

7. Then run the app for visual check:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Prompt source workflow

Later, user will send screenshots or final preview images style by style.
For each final preview, Codex should add:
- style/template id
- asset filename
- visual description
- generation prompt for real user output
- forbidden details
- notes on pose, crop, outfit, location, light

Cursor should not write those prompts into backend until the user confirms the final prompt pack.

## Photoshoot prompt pack v1 - based on user-approved preview screenshots

These prompts are intended for real user generation, not for preview generation.

Important prompt rule for all flows:

1. Every frame 0 prompt must objectively explain what the input image is:
   "You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into the described photoshoot scene."

2. Every frame 1 and frame 2 continuation prompt must objectively explain both references:
   "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a new photo of the same person in the same photoshoot, but with a clearly different pose, crop and camera angle."

3. This objective reference-role block must be added not only to photoshoot prompts, but also to all single-template photo prompts. For single templates, the wording is simpler:
   "You are given one uploaded user photo. Use it as the identity reference. Keep the same person and transform only the clothes, background, pose, lighting and style described below."

4. Never let the model copy the previous frame exactly. Continuation frames must keep one style, but change at least 3 things: crop, body angle, gaze direction, hands/arms, camera distance, seated/standing position or background framing.

5. Avoid prompt wording that creates a new person, a new outfit color, a new location or a different age.

### `urban_portrait` - Городской портрет

Visual target: elegant city street portrait near a stone building facade, beige/light outfit, calm premium daytime mood.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into an elegant city portrait in a soft beige urban look.

Generate a photorealistic portrait on a quiet city sidewalk near a light stone building facade with columns and large windows. The person wears a light cream blouse or knit top, beige cardigan or light trench-style layer, and beige trousers. Chest-up to half-body framing, relaxed posture, looking gently into the camera, soft natural daylight, premium clean city atmosphere.

Keep the outfit light beige/cream, keep the background as an elegant city street facade, no studio background, no office blazer, no evening look, no black clothing, no crowd, no cars dominating the frame.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a new photo of the same person in the same city photoshoot, not a copy of Image 2.

Create a medium portrait near the same stone city facade, with the body turned slightly three-quarters to the camera. The person stands closer to a doorway or column, one hand relaxed near the cardigan or pocket, gaze softly into camera or slightly off-camera. Same beige outfit, same soft daylight, same elegant urban palette.

Change the crop and pose from the first frame: different body angle, different hand position, slightly different background framing. Do not change the outfit color or location.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct photo of the same city photoshoot.

Create a wider waist-up or almost full-body city portrait on the sidewalk, the person walking slowly or standing with one hand in a pocket, building facade receding into the background. Same light cream/beige outfit, same soft neutral daylight, polished city lifestyle mood.

The third frame must be clearly different from frames 0 and 1: wider camera distance, more visible street depth, different arm position and gaze. Do not create a studio portrait or business suit look.
```

### `tender_photoshoot` - Нежная фотосессия

Visual target: soft beige interior, cozy knit sweater, cream sofa, curtains, pampas grass, warm feminine mood.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a gentle cozy indoor portrait.

Generate a photorealistic soft beige interior photoshoot: the person sits on a cream sofa, wearing a light beige or cream knit sweater and soft neutral pants. Warm daylight through sheer curtains, pampas grass or soft dried flowers in the background, calm gentle smile, close half-body framing.

Keep the palette cream, beige and warm white. No dark dramatic lighting, no business jacket, no outdoor park, no black clothes, no glamour evening mood.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a new photo from the same tender indoor photoshoot.

Create a medium seated portrait on the same cream sofa. The person leans slightly forward, one elbow resting on the knee or sofa arm, one hand gently near the chin or cheek. Same cream knit sweater, same soft beige interior, same window daylight and calm warm color grading.

Make it a different composition from the first frame: different hand placement, different head tilt, slightly closer or more centered crop. Do not change the room, outfit or light.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct photo from this same tender photoshoot.

Create a soft close portrait with the person seated comfortably, shoulders relaxed, gentle smile, face slightly turned toward the light. Cream sofa and pampas/dried flowers remain softly visible in the background, same beige knit outfit and soft daylight.

The third photo should feel closer and more intimate than the first two, with a different crop and gaze. Keep one consistent outfit and location.
```

### `home_portrait` - Домашний портрет

Visual target: bright living room, sofa, cozy cardigan over white top, warm daylight, natural home comfort.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a warm home portrait.

Generate a photorealistic portrait in a bright cozy living room. The person sits on a sofa near a window, wearing a soft cream cardigan over a white top, relaxed and approachable. Background includes warm neutral home decor, a blanket, vase or plants, soft daylight, clean natural color palette.

Keep it realistic and simple: no studio backdrop, no formal suit, no dark evening light, no cluttered room, no luxury hotel look.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a second home portrait in the same living room.

Create a medium seated portrait with the person sitting more centered on the sofa, hands relaxed on knees or folded naturally, looking into the camera with a soft friendly expression. Same cream cardigan, white top, warm window daylight, neutral home decor.

Change the pose and crop from the first frame. Keep the same room, outfit and cozy natural mood.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct photo from the same home portrait session.

Create a wider relaxed portrait on the sofa with more of the blanket and living room visible. The person sits comfortably, slightly angled, hands resting naturally, soft direct gaze or gentle smile. Same cream cardigan, white top, warm neutral interior and daylight.

Make the third frame wider and calmer than the first two. Do not change the outfit, background style or lighting.
```

### `cafe_city` - Кафе и город

Visual target: cafe by window, olive/beige jacket with white shirt, cup of coffee, city visible through glass, warm cafe light.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a cafe and city portrait.

Generate a photorealistic portrait at a small cafe table near a large window. The person wears an olive, sage or beige jacket over a crisp white blouse or shirt. A coffee cup is on the table, warm cafe lamps and city street visible through the window, calm confident expression, elegant lifestyle mood.

Keep the outfit olive/beige plus white shirt. Keep cafe-window-city atmosphere. No studio gray background, no black evening dress, no office desk, no crowded restaurant.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a second photo in the same cafe and city photoshoot.

Create a closer portrait by the cafe window with the coffee cup slightly visible in the foreground. The person sits or leans naturally, body turned three-quarters, gaze into camera or softly toward the window. Same olive/beige jacket, white shirt, warm cafe light and street-through-window background.

Change the pose, crop and gaze from the first frame. Do not change the outfit, cafe location or warm color grading.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct photo from this cafe-city session.

Create a portrait just outside or near the cafe entrance, the city street and cafe windows visible behind the person. The person stands in the same olive/beige jacket and white shirt, relaxed confident posture, soft daylight mixed with warm cafe light.

The third frame should show more city context and a standing pose. Keep it part of the same session, not a different outfit or different place.
```

### `business_brand` - Бизнес-портрет

Visual target: neutral gray/beige studio, light textured blazer, white top, clean professional personal-brand portrait.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a clean business brand portrait.

Generate a photorealistic professional portrait on a warm neutral gray or beige studio background. The person wears a light beige, gray or cream textured blazer over a white top. Chest-up framing, calm confident expression, soft professional daylight, clean personal-brand style.

Keep the outfit light and professional. No black top, no off-shoulder clothes, no floral wallpaper, no park, no evening glamour, no corporate office clutter.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a second business brand portrait in the same studio session.

Create a medium portrait with the person standing or seated, hands lightly joined at waist level or resting naturally, body facing the camera more directly. Same light textured blazer, white top, neutral gray-beige background and soft professional light.

Change the crop and hand position from the first frame. Keep the same clean professional mood and outfit.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct business brand portrait.

Create a three-quarter angle portrait, the person turned slightly to one side while still engaging the camera. Same light blazer and white top, same neutral studio wall, soft shadows, polished expert look.

Make this frame different through body angle and camera distance. Do not change to a dark suit, outdoor location or glamour styling.
```

### `travel_portrait` - Портрет в путешествии

Visual target: old town narrow street, beige linen jacket/cardigan, white top, cobblestones, warm daylight, relaxed travel mood.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a warm travel portrait.

Generate a photorealistic portrait in a charming old European town street with stone walls, warm beige buildings, cobblestone path and soft daylight. The person wears a beige linen jacket, cardigan or light trench over a white top. Chest-up framing, relaxed smile, travel lifestyle mood.

Keep the location as old town/travel street. No studio, no business blazer look, no modern office, no beach, no winter clothing.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a second photo from the same travel portrait session.

Create a medium portrait in the same narrow street, body turned slightly three-quarters, one hand gently touching the lapel/cardigan or holding a small strap. Same beige travel outfit, white top, cobblestone street and warm old-town background.

Change the pose and gaze from the first frame. Keep the same travel location and warm color palette.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct photo from this travel session.

Create a wider portrait with the person walking slowly along a stone wall or turning back slightly on a cobblestone street. More of the old town alley is visible, same beige jacket/cardigan, same white top, soft daylight, relaxed travel expression.

The third frame should be more side-view or walking-oriented. Do not change to a different city style, studio background or business outfit.
```

### `park_walk` - Прогулка в парке

Visual target: green park path, mint cardigan, white top, soft daylight, calm friendly walk.

Frame 0:

```text
You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a calm park walk portrait.

Generate a photorealistic portrait in a green park with trees and a soft path in the background. The person wears a mint, pale green or light pastel cardigan over a white top. Chest-up framing, relaxed natural smile, soft daylight, fresh calm spring/summer palette.

Keep the outfit mint/white and the location green park. No black clothes, no studio, no business suit, no evening light, no winter snow.
```

Frame 1:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate a second photo from the same park walk session.

Create a medium portrait by a park bench or railing, the person leaning lightly or resting hands naturally, possibly holding a light tote bag or cardigan edge. Same mint cardigan, white top, green trees and soft park daylight.

Change hand position, crop and body angle from the first frame. Keep the same outfit and fresh green park mood.
```

Frame 2:

```text
You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate the third distinct photo from this park walk session.

Create a wider walking portrait on the park path, the person standing or slowly walking with hands relaxed, body turned slightly to the side, trees framing the background. Same mint cardigan, white top, soft daylight and natural green color grading.

The third frame should be wider and more lifestyle-oriented than the first two. Do not change to city street, studio, black outfit or formal business styling.
```

