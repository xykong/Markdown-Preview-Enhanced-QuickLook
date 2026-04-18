# RTL Language Support Test / اختبار دعم اللغات من اليمين إلى اليسار

This document tests automatic RTL detection in FluxMarkdown.
Press `Space` in Finder to preview — the text below should render right-to-left.

---

## Arabic / العربية

### Prose

مرحباً بكم في اختبار دعم اللغات من اليمين إلى اليسار. هذا المستند مكتوب باللغة العربية ويحتوي على فقرات متعددة لاختبار الكشف التلقائي عن اتجاه النص.

الفقرة الثانية تحتوي على نص عربي إضافي للتأكد من أن النظام يكتشف بشكل صحيح أن معظم المحتوى مكتوب بلغة تُقرأ من اليمين إلى اليسار.

### List / قائمة

- العنصر الأول
- العنصر الثاني
- العنصر الثالث

### Blockquote / اقتباس

> "إن الله لا يغير ما بقوم حتى يغيروا ما بأنفسهم"

### Table / جدول

| الاسم | العمر | المدينة |
|-------|-------|---------|
| أحمد  | 30    | القاهرة |
| فاطمة | 25    | الرياض  |
| محمد  | 35    | دبي     |

### Code block (should remain LTR) / كتلة الكود

```python
def greet(name):
    return f"مرحباً، {name}!"

print(greet("العالم"))
```

---

## Hebrew / עברית

### Prose

שלום וברוכים הבאים למסמך בדיקה לתמיכה בכיוון מימין לשמאל. מסמך זה כתוב בעברית ומכיל מספר פסקאות לבדיקת הזיהוי האוטומטי של כיוון הטקסט.

הפסקה השנייה מכילה טקסט עברי נוסף כדי לוודא שהמערכת מזהה נכון שרוב התוכן כתוב בשפה הנקראת מימין לשמאל.

### List / רשימה

- פריט ראשון
- פריט שני
- פריט שלישי

### Blockquote / ציטוט

> "אם תרצו, אין זו אגדה" — תיאודור הרצל

---

## Mixed content note

The RTL detection threshold is **30%** — if more than 30% of non-whitespace characters
are Arabic or Hebrew, the entire preview container gets `dir="rtl"`.

This document is intentionally Arabic/Hebrew-heavy to trigger that threshold.
