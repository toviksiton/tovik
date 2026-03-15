import Foundation

// MARK: - ChallengeBank
// 50 Hebrew challenges (5 per ChallengeType), all static templates.

enum ChallengeBank {

    static let all: [ChallengeTemplate] = [
        // ── CRITICAL THINKING (5) ───────────────────────────────────────────
        ChallengeTemplate(
            type: .criticalThinking,
            prompt: "סגור את ה-AI. הסבר לעצמך בקול את הרעיון שחיפשת — במילים שלך בלבד.",
            durationSeconds: 60,
            intensity: 8,
            researchNote: "מבוסס על מחקר MIT 2025 — שימוש ב-AI מפחית קישוריות מוחית ב-55%",
            requiresStationary: false
        ),
        ChallengeTemplate(
            type: .criticalThinking,
            prompt: "בחר טענה שקיבלת מ-AI היום. מצא שלושה חורים בהיגיון שלה — ללא עזרים.",
            durationSeconds: 90,
            intensity: 9,
            researchNote: "מבוסס על Gerlich 2025 — חשיבה ביקורתית נשחקת עם תלות ב-AI",
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .criticalThinking,
            prompt: "מה היה הפתרון שלך לבעיה האחרונה לפני שפנית ל-AI? בנה אותו מחדש עכשיו.",
            durationSeconds: 120,
            intensity: 9,
            researchNote: "אימון עצמאות קוגניטיבית — MIT 2025",
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .criticalThinking,
            prompt: "כתוב טיעון נגד הדעה האחרונה שהסכמת איתה. הגן עליה בכנות.",
            durationSeconds: 90,
            intensity: 8,
            requiresStationary: false
        ),
        ChallengeTemplate(
            type: .criticalThinking,
            prompt: "בחר החלטה שקיבלת השבוע. מה המידע שהיה חסר לך? מה היית עושה אחרת?",
            durationSeconds: 60,
            intensity: 7,
            requiresStationary: false
        ),

        // ── DEEP COGNITIVE (5) ──────────────────────────────────────────────
        ChallengeTemplate(
            type: .deepCognitive,
            prompt: "כתוב 3 טיעונים נגד ההחלטה האחרונה שקיבלת. ללא עזרים. מהזיכרון.",
            durationSeconds: 120,
            intensity: 9,
            researchNote: "חיזוק זיכרון עבודה — MIT 2025",
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .deepCognitive,
            prompt: "תכנן את המשימה הכי מורכבת שלך מחר — שלבים, מכשולים, פתרונות. ללא רשימה.",
            durationSeconds: 120,
            intensity: 10,
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .deepCognitive,
            prompt: "הסבר מושג מתחום עבודתך לאדם בן 10. ודא שהוא מובן לחלוטין — אחד ורק אחד.",
            durationSeconds: 90,
            intensity: 8,
            requiresStationary: false
        ),
        ChallengeTemplate(
            type: .deepCognitive,
            prompt: "מה הדבר שלמדת הכי לאחרונה? הכן הסבר של 90 שניות בלי לחפש מידע נוסף.",
            durationSeconds: 90,
            intensity: 7,
            requiresStationary: false
        ),
        ChallengeTemplate(
            type: .deepCognitive,
            prompt: "צייר בראשך את הקשרים בין שלושה תחומים שונים בעבודה שלך. מה מחבר ביניהם?",
            durationSeconds: 60,
            intensity: 8,
            requiresStationary: true
        ),

        // ── MEMORY (5) ──────────────────────────────────────────────────────
        ChallengeTemplate(
            type: .memory,
            prompt: "תסכם בקול את שלושת הדברים שה-AI יצר עבורך היום. מהזיכרון — לא מהמסך.",
            durationSeconds: 60,
            intensity: 7,
            researchNote: "אימון זיכרון עבודה — MIT 2025",
            audioOnly: true
        ),
        ChallengeTemplate(
            type: .memory,
            prompt: "מי הם חמשת האנשים שדיברת איתם הכי הרבה השבוע? מה אמרת לכל אחד מהם?",
            durationSeconds: 90,
            intensity: 6,
            audioOnly: true
        ),
        ChallengeTemplate(
            type: .memory,
            prompt: "הזכר את שלוש הפגישות האחרונות שהיו לך. מה הוחלט בכל אחת? מה הצעד הבא?",
            durationSeconds: 60,
            intensity: 7,
            audioOnly: true
        ),
        ChallengeTemplate(
            type: .memory,
            prompt: "ספור לאחור מ-97 בקפיצות של 4 — בקול, בלי לעצור, בלי להתחיל מחדש.",
            durationSeconds: 45,
            intensity: 8,
            audioOnly: true
        ),
        ChallengeTemplate(
            type: .memory,
            prompt: "זכור את ארוחת הבוקר של שלשום. תאר אותה בפרטים — צבעים, טעמים, מקום.",
            durationSeconds: 45,
            intensity: 5,
            audioOnly: true
        ),

        // ── QUICK REFLECT (5) ───────────────────────────────────────────────
        ChallengeTemplate(
            type: .quickReflect,
            prompt: "מה נקודת הפתיחה שלך לפגישה הקרובה? משפט אחד, ברור ומדויק.",
            durationSeconds: 45,
            intensity: 4
        ),
        ChallengeTemplate(
            type: .quickReflect,
            prompt: "משפט אחד: מה הרגשת בשעה האחרונה?",
            durationSeconds: 30,
            intensity: 2
        ),
        ChallengeTemplate(
            type: .quickReflect,
            prompt: "מה הדבר הכי חשוב שעשית היום עד עכשיו? האם זה עונה על הצורך האמיתי?",
            durationSeconds: 45,
            intensity: 4
        ),
        ChallengeTemplate(
            type: .quickReflect,
            prompt: "ב-10 שניות: מה הצעד הבא שאתה חייב לעשות? עכשיו — תעשה אותו.",
            durationSeconds: 30,
            intensity: 3
        ),
        ChallengeTemplate(
            type: .quickReflect,
            prompt: "אם היום היה מסתיים עכשיו — מה לא היה גמור? כתוב אחד, רק אחד.",
            durationSeconds: 45,
            intensity: 3
        ),

        // ── RECOVERY (5) ────────────────────────────────────────────────────
        ChallengeTemplate(
            type: .recovery,
            prompt: "עצור. 3 צלילים. 2 תחושות בגוף. 1 מחשבה שמגיעה. תן לה לעבור.",
            durationSeconds: 60,
            intensity: 1,
            researchNote: "פרוטוקול 5-4-3-2-1 להפחתת סטרס קוגניטיבי"
        ),
        ChallengeTemplate(
            type: .recovery,
            prompt: "נשום: 4 שניות פנימה, 7 שניות החזק, 8 שניות החוצה. חזור 3 פעמים.",
            durationSeconds: 60,
            intensity: 1,
            researchNote: "טכניקת 4-7-8 להורדת קורטיזול — Forte 2025"
        ),
        ChallengeTemplate(
            type: .recovery,
            prompt: "סרוק את גופך מהראש לכפות הרגליים. היכן יש מתח? שחרר אותו בנשיפה.",
            durationSeconds: 90,
            intensity: 1
        ),
        ChallengeTemplate(
            type: .recovery,
            prompt: "עצום עיניים 30 שניות. אל תחשוב על כלום — רק על הנשימה. אם מחשבה מגיעה, שחרר.",
            durationSeconds: 45,
            intensity: 1
        ),
        ChallengeTemplate(
            type: .recovery,
            prompt: "מה הדבר האחד שלא חייב להיות מושלם היום? תן לעצמך רשות לשחרר אותו.",
            durationSeconds: 45,
            intensity: 2
        ),

        // ── SENSORY (5) ─────────────────────────────────────────────────────
        ChallengeTemplate(
            type: .sensory,
            prompt: "מה הצבע שהכי בולט סביבך עכשיו? למה דווקא הוא תפס את תשומת לבך?",
            durationSeconds: 45,
            intensity: 3
        ),
        ChallengeTemplate(
            type: .sensory,
            prompt: "הקשב. כמה שכבות של רעש יש סביבך? תאר כל אחת בנפרד.",
            durationSeconds: 45,
            intensity: 3,
            audioOnly: true
        ),
        ChallengeTemplate(
            type: .sensory,
            prompt: "גע במשהו קרוב אליך. תאר את המרקם שלו ב-5 מילים שמעולם לא השתמשת בהן.",
            durationSeconds: 60,
            intensity: 4
        ),
        ChallengeTemplate(
            type: .sensory,
            prompt: "בלי להסתכל — כמה אנשים נמצאים בסביבה שלך? איך ידעת?",
            durationSeconds: 30,
            intensity: 5
        ),
        ChallengeTemplate(
            type: .sensory,
            prompt: "מה הריח הדומיננטי עכשיו? מה הוא מזכיר לך? מאיפה הזיכרון הזה?",
            durationSeconds: 45,
            intensity: 3
        ),

        // ── EMOTIONAL (5) ───────────────────────────────────────────────────
        ChallengeTemplate(
            type: .emotional,
            prompt: "חשוב על מישהו שאהבת — מה לא אמרת לו? למה?",
            durationSeconds: 60,
            intensity: 6,
            requiresStationary: false
        ),
        ChallengeTemplate(
            type: .emotional,
            prompt: "מה הרגש שהכי קשה לך להודות בו? בפני מי תוכל להגיד אותו?",
            durationSeconds: 60,
            intensity: 7,
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .emotional,
            prompt: "מה הדבר שהכי גאה בו בעצמך השנה? אמור אותו בקול — לא בבטן.",
            durationSeconds: 45,
            intensity: 5
        ),
        ChallengeTemplate(
            type: .emotional,
            prompt: "מי פגע בך לאחרונה — בלי שהתכוון? האם יודע? האם חשוב שידע?",
            durationSeconds: 60,
            intensity: 6
        ),
        ChallengeTemplate(
            type: .emotional,
            prompt: "תן שם לרגש שאתה מרגיש עכשיו ממש. לא 'בסדר' — רגש אמיתי, בשם.",
            durationSeconds: 30,
            intensity: 4
        ),

        // ── SOCIAL (5) ──────────────────────────────────────────────────────
        ChallengeTemplate(
            type: .social,
            prompt: "בחר אדם בסביבה. מה הסיפור שלו לדעתך? נמק — מה רואה עיניך?",
            durationSeconds: 60,
            intensity: 5
        ),
        ChallengeTemplate(
            type: .social,
            prompt: "מי האדם שהכי מעצב אותך בלי שהוא יודע? מה הוא לימד אותך?",
            durationSeconds: 60,
            intensity: 6,
            requiresStationary: false
        ),
        ChallengeTemplate(
            type: .social,
            prompt: "איזו שאלה לא שאלת מישהו קרוב כבר יותר מחודש? למה לא שאלת?",
            durationSeconds: 45,
            intensity: 5
        ),
        ChallengeTemplate(
            type: .social,
            prompt: "מה ההבדל בין האדם שאתה בעבודה לאדם שאתה בבית? מה מסביר את ההבדל?",
            durationSeconds: 60,
            intensity: 6,
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .social,
            prompt: "מי צריך אותך עכשיו ולא ביקש? מה תוכל לתת לו ביוזמתך?",
            durationSeconds: 45,
            intensity: 5
        ),

        // ── CREATIVE (5) ────────────────────────────────────────────────────
        ChallengeTemplate(
            type: .creative,
            prompt: "מצא שם לעסק שעושה משהו שלא קיים. תאר אותו ב-2 משפטים.",
            durationSeconds: 120,
            intensity: 6
        ),
        ChallengeTemplate(
            type: .creative,
            prompt: "בחר שני עצמים שלא קשורים סביבך. המצא שימוש חדש לשניהם יחד.",
            durationSeconds: 60,
            intensity: 5
        ),
        ChallengeTemplate(
            type: .creative,
            prompt: "המצא כלל חדש לחברה שלך שאף אחד לא העלה על הדעת. הגדר אותו בדיוק.",
            durationSeconds: 90,
            intensity: 7,
            requiresStationary: true
        ),
        ChallengeTemplate(
            type: .creative,
            prompt: "כתוב כותרת לעיתון עבור היום שלך — כאילו זה חדשות ראשיות.",
            durationSeconds: 45,
            intensity: 4
        ),
        ChallengeTemplate(
            type: .creative,
            prompt: "תאר את עבודתך לאדם שחי לפני 200 שנה. מה הוא הכי לא יבין?",
            durationSeconds: 90,
            intensity: 6
        ),

        // ── PHYSICAL MIND (5) ───────────────────────────────────────────────
        ChallengeTemplate(
            type: .physicalMind,
            prompt: "תוך כדי הליכה — ספור לאחור מ-100 בקפיצות של 7. לא תעצור, לא תחזור.",
            durationSeconds: 60,
            intensity: 7,
            audioOnly: true
        ),
        ChallengeTemplate(
            type: .physicalMind,
            prompt: "עמוד על רגל אחת. בעת כך — מנה 5 ערים שמתחילות בא׳. עם עיניים עצומות.",
            durationSeconds: 30,
            intensity: 6
        ),
        ChallengeTemplate(
            type: .physicalMind,
            prompt: "תוך כדי 20 קפיצות במקום — זכור את הפריטים: תפוח, מכונית, ירח, שולחן, דג.",
            durationSeconds: 45,
            intensity: 7
        ),
        ChallengeTemplate(
            type: .physicalMind,
            prompt: "הניע את ידך הימנית במעגלים ורגלך הימנית באליפסה בו-זמנית. 30 שניות.",
            durationSeconds: 30,
            intensity: 5
        ),
        ChallengeTemplate(
            type: .physicalMind,
            prompt: "תוך כדי הליכה — אמור לסירוגין: שם של בעל חיים, שם של מדינה. 10 זוגות.",
            durationSeconds: 60,
            intensity: 6,
            audioOnly: true
        )
    ]

    // MARK: - Access helpers

    /// All templates for a given ChallengeType
    static func templates(for type: ChallengeType) -> [ChallengeTemplate] {
        all.filter { $0.type == type }
    }
}
