# AI Chat Features - Quick Reference

## 🚀 Quick Start

### For Admins
1. Go to **Settings → AI Chat Settings** (admin only)
2. Configure settings using dropdowns
3. Add resources (knowledge base)
4. Save settings

### For Users
- Chat with Sampul AI
- Action buttons appear automatically
- Click buttons to navigate to features

---

## 📋 Action Button Format

### Structured Markers (Recommended)
```
[ACTION:route:label]
[ACTION:trust_create:Create Trust Fund]
[ACTION:add_asset:Tambah Aset]
```

### Supported Routes
- `trust_create` - Create Trust Fund
- `trust_management` - View Trust Funds
- `hibah_management` - View Hibah
- `will_management` - View Will
- `add_asset` - Add Asset
- `assets_list` - View Assets
- `add_family` - Add Family Member
- `family_list` - View Family
- `executor_management` - Manage Executors
- `checklist` - View Checklist
- `extra_wishes` - Extra Wishes

---

## ⚙️ Settings Quick Reference

### Max Tokens (Response Length)
| Value | Description |
|-------|-------------|
| 100 | Short - Very brief |
| 200 | Medium-Short - Concise |
| 300 | Medium - Balanced |
| 500 | Medium-Long - Detailed |
| 800 | Long - Comprehensive |
| 1200 | Very Long - Extensive |

### Temperature (Response Style)
| Value | Description |
|-------|-------------|
| 0.0 | Very Consistent |
| 0.3 | Consistent |
| 0.5 | Balanced |
| 0.7 | Creative |
| 1.0 | Very Creative |
| 1.5 | Extremely Creative |

---

## 🔍 Testing Checklist

- [ ] Action buttons appear when AI mentions features
- [ ] Markers `[ACTION:...]` are hidden from display
- [ ] Buttons navigate correctly
- [ ] Works in English and Malay
- [ ] Settings apply correctly
- [ ] Resources are included in prompts
- [ ] Disclaimer shows below input

---

## 🐛 Common Issues

**Buttons not appearing?**
- Check AI response includes `[ACTION:...]` markers
- Verify route names match exactly
- Check console for errors

**Settings not applying?**
- Wait 5 minutes (cache) or restart app
- Verify `is_active = true` in database
- Check console logs

---

## 📁 Key Files

- `lib/services/ai_action_detector.dart` - Action detection
- `lib/services/ai_chat_settings_service.dart` - Settings CRUD
- `lib/models/ai_chat_settings.dart` - Settings model
- `lib/screens/admin_ai_settings_screen.dart` - Admin UI
- `ai_chat_settings_setup.sql` - Database schema

---

## 💡 Tips

1. **Start Conservative**: Use Medium (300) + Balanced (0.5)
2. **Test Changes**: Always test before production
3. **Use Markers**: Train AI to use `[ACTION:route:label]` format
4. **Update Resources**: Keep knowledge base current
5. **Monitor**: Check console logs for debugging

---

**See `AI_CHAT_FEATURES_DOCUMENTATION.md` for full documentation**
