# UI / screenshot review checklist (iPhone 16 simulator)

Проверка выполняется на macOS с Xcode 27. В среде Windows визуальная проверка недоступна.

## Экраны

- [ ] Splash / Welcome / Onboarding (все 10 шагов, в том числе «Не знаю» и «Пропустить»)
- [ ] Home — Cycle и Home — Planning
- [ ] Calendar (сентябрь→октябрь, високосный февраль, подсветка сегодня)
- [ ] Day Detail, Period Editor
- [ ] Symptom / Mood / LH / Pregnancy / Temperature / Mucus editors
- [ ] Fertility Insights, Analytics, Historical Cycles
- [ ] Recommendations, Medical Library, PDF Reports
- [ ] Settings, Mode Switcher, Notifications, Privacy, Backup, About

## Состояния

- [ ] empty / loading / populated / error где применимо
- [ ] Отсутствуют фейковые данные в production-интерфейсе

## Доступность и безопасная зона

- [ ] Нет обрезанного текста (особенно русские склонения и длинные слова)
- [ ] Нет наложения на Dynamic Island и Home Indicator
- [ ] Safe areas сверху/снизу, tab bar на своём месте
- [ ] Keyboard avoidance в формах и TextEditor
- [ ] Календарь не выходит за границы экрана
- [ ] Dynamic Type: accessibility3 — без обрезаний
- [ ] VoiceOver: подписи всех интерактивных элементов
- [ ] Reduce Motion: анимации отключены
- [ ] Тёмная тема: читаема, без насыщенного розового
- [ ] Модальные листы закрываются, действия работают
- [ ] App switcher: содержимое скрыто
