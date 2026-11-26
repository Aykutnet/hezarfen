# Tarihle Şaka Olmaz

> Oynarken güldüren, bittiğinde düşündüren oyunlar.

## Oyunlar (yapım sırası)

| # | Oyun | Oynanış | Durum |
|---|---|---|---|
| 1 | 🇹🇷 Hezarfen – Uçtun da Ne Oldu? | Boğaz'ı geç, mahalleliden kaç. | ✅ Yayında |
| 2 | 🇹🇷 Figânî – Ben Yazmadım! | Şiir yüzünden Pargalı'dan kaç. | Sıradaki |
| 3 | 🇹🇷 Takiyüddin – Teleskobu Sakla! | Rasathaneyi kurtarmaya çalış. | |
| 4 | 🇮🇹 Galileo – Vallahi Dönüyor! | Engizisyon karşısında Dünya'nın döndüğünü kanıtla. | |
| 5 | 🇺🇸 Salem – Ben Cadı Değilim! | Her hareketinden şüphelenen kasabalıları ikna et. | |
| 6 | 🇦🇹 Semmelweis – Yıka Şu Elini! | Doktorlara zorla el yıkatmaya çalış. | |
| 7 | 🇦🇺 Emu Savaşı – Kuşlara Yenildik! | Avustralya ordusunu emulara karşı yönet. | |
| 8 | 🇮🇹 Bruno – Keşke Susaydım! | Fikirlerin yüzünden başına açılan belalardan kurtul. | |

## Müzik ve ses: hangi araç, ne için?

| İş | Araç |
|---|---|
| Türkçe rap şarkıları | **Suno v6** |
| Hikâye anlatan şarkılar | **Suno v6** |
| Oyuna özel soundtrack albümü | **Suno v6** |
| Vokalli menü ve jenerik müzikleri | **Suno v6** |
| Final için duygusal şarkılar | **Suno v6** |
| Mizahi rap, karakterler arası rap kapışmaları | **Suno v6** |
| Ses efektleri (rüzgâr, uçuş, kanat, çarpışma, düşme, kavga, darbe, menü/arayüz, kısa oyun efektleri) | **ElevenLabs** |
| Ortam sesleri (kalabalık, mahalle, tarihî şehir atmosferi) | **ElevenLabs** |
| Seslendirme (karakter diyalogları, NPC, anlatıcı, tepki ve bağırışlar, oyun içi anonslar) | **ElevenLabs** (alternatif: Gemini TTS) |
| Enstrümantal: döngüsel fon müziği, gerilim/atmosfer, belirli süreli kısa müzik, geçiş ve bölüm sonu müzikleri | **ElevenLabs** |

- Şarkı sözlerini LLM yazar; müzik ve vokali Suno üretir.
- Suno v6, Eleven Music v2 ve v2.5 ile karşılaştırıldı. Rap performansı, flow, vokal ve beat uyumunda Suno daha başarılı bulundu.
- Gemini TTS Hezarfen'de denendi; Türkçe repliklerde İngilizce aksan çıktığı için ElevenLabs'e geçildi.

## Genel üretim kuralları

- Müzik, seslendirme ve ses efektleri ayrı asset kategorileri olarak yönetilir.
- Ses efektleri ve fon müzikleri gerektiğinde döngüsel kullanıma uygun hazırlanır.
- Godot 4 ile uyumlu ses formatları kullanılır.
- Her oyunun kendine özgü bir müzikal kimliği olur.
- Şarkılar yalnızca mizahi olmak zorunda değil; karakterlerin dramatik hikâyeleri de işlenir.
- Tarihî gerçekler, rivayetler ve mizahi kurgu birbirinden ayrılır.

## Albümler

### 1. Hezarfen — Kanatlar Sırtında

1. Uçtun da Ne Oldu?
2. Mahalle Bana Deli Dedi
3. Üsküdar Mahalle Diss
4. Bir Kese Altın

Dört şarkı da Suno v6 ile üretildi. Bir Kese Altın'ın tercih edilen sürümü: `8d6c03a4-442a-4b0a-a4eb-bce072ce45fb`.

YouTube oynatma listesi: https://www.youtube.com/playlist?list=PLMtxgvOk9Juc
