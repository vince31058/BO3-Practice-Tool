#include "ImGuiHelper.h"

#define ICON_FA_ARROW_LEFT "\xef\x81\xa0"
#define ICON_FA_CIRCLE_QUESTION "\xef\x81\x99"

namespace ImGuiHelper {

	PopupStates PopupWrapper::s_PrepState;
	PopupStates PopupWrapper::s_OpenState;
	std::queue<PopupStates> PopupWrapper::s_StateQueue;

	void MultiSpanSelection::Render(int selectionIndex)
	{
		if (!m_Selections.size()) {
			return;
		}

		int prevItem = m_Index;

		int index = 0;
		for (int i = 0; i < selectionIndex; i++) {
			index += static_cast<int>(m_Selections[i].m_Items.size());
		}

		for (int i = index; i < index + m_Selections[selectionIndex].m_Items.size(); i++) {
			const bool selected = m_Index == i;
			if (ImGui::Selectable(m_Selections[selectionIndex].m_Items[i - index].c_str(), selected)) {
				m_Index = i;
			}
			if (selected) {
				ImGui::SetItemDefaultFocus();
			}
		}

		if (prevItem != m_Index) {
			m_Changed = true;
		}
	}

	int MultiSpanSelection::GetArrIndex() const
	{
		int indexArr = 0;
		int indexItem = 0;
		for (const SelectionData& data : m_Selections) {
			if (indexItem + static_cast<int>(data.m_Items.size()) < m_Index + 1) {
				indexItem += static_cast<int>(data.m_Items.size());
				indexArr++;
			}
			else {
				return indexArr;
			}
		}

		return -1;
	}

	std::pair<int, int> MultiSpanSelection::GetMultiIndex() const
	{
		int indexArr = 0;
		int indexItem = 0;
		for (const SelectionData& data : m_Selections) {
			if (indexItem + static_cast<int>(data.m_Items.size()) < m_Index + 1) {
				indexItem += static_cast<int>(data.m_Items.size());
				indexArr++;
			}
			else {
				return { indexArr, m_Index - indexItem };
			}
		}

		return { -1, -1 };
	}

	std::string MultiSpanSelection::GetItemAtIndex() const
	{
		int index = 0;
		for (const SelectionData& data : m_Selections) {
			if (index + static_cast<int>(data.m_Items.size()) < m_Index + 1) {
				index += static_cast<int>(data.m_Items.size());
			}
			else {
				return data.m_Items[m_Index - index];
			}
		}
		
		return "Not Found";
	}

	bool Selection::Render(const std::vector<std::string>& items, int& index)
	{
		int prevItem = index;

		for (int i = 0; i < static_cast<int>(items.size()); i++) {
			const bool selected = index == i;
			if (ImGui::Selectable(items[i].c_str(), selected)) {
				index = i;
			}
			if (selected) {
				ImGui::SetItemDefaultFocus();
			}
		}

		return prevItem != index;
	}

	bool Selection::RenderBGB(const std::vector<BGB>& items, int& index)
	{
		int prevItem = index;

		for (int i = 0; i < static_cast<int>(items.size()); i++) {
			const bool selected = index == i;
			if (ImGui::Selectable(items[i].m_Name.c_str(), selected)) {
				index = i;
			}
			if (selected) {
				ImGui::SetItemDefaultFocus();
			}
		}

		return prevItem != index;
	}

	bool Selection::RenderBGBPreset(const std::vector<BGBPreset>& items, int& index)
	{
		int prevItem = index;

		for (int i = 0; i < static_cast<int>(items.size()); i++) {
			const bool selected = index == i;
			if (ImGui::Selectable(items[i].m_Name.c_str(), selected)) {
				index = i;
			}
			if (selected) {
				ImGui::SetItemDefaultFocus();
			}
		}

		return prevItem != index;
	}

	bool Selection::RenderWeaponLoadout(const std::vector<MenuWeaponPreset>& items, int& index)
	{
		int prevItem = index;

		for (int i = 0; i < static_cast<int>(items.size()); i++) {
			const bool selected = index == i;
			if (ImGui::Selectable(items[i].m_Name.c_str(), selected)) {
				index = i;
			}
			if (selected) {
				ImGui::SetItemDefaultFocus();
			}
		}

		return prevItem != index;
	}

	void TextFont::Render(std::string_view text, ImFont* font, bool push, bool pop)
	{
		if (push) {
			ImGui::PushFont(font);
		}
		ImGui::Text(text.data());
		if (pop) {
			ImGui::PopFont();
		}
	}

	void TextFont::RenderWrapped(std::string_view text, ImFont* font, bool push, bool pop)
	{
		if (push) {
			ImGui::PushFont(font);
		}
		ImGui::TextWrapped(text.data());
		if (pop) {
			ImGui::PopFont();
		}
	}

	void PopupWrapper::PrepPopup(PopupStates state)
	{
		if (state == None || state == Open) {
			return;
		}
		if (s_PrepState == None) {
			s_PrepState = state;
		}
		else {
			s_StateQueue.push(state);
		}
	}

	void PopupWrapper::OpenPopup(PopupStates state)
	{
		if (state == None || state == Open) {
			return;
		}
		s_PrepState = Open;
		s_OpenState = state;
	}

	void PopupWrapper::ClosePopup()
	{
		s_OpenState = None;
		if (s_StateQueue.size()) {
			s_PrepState = s_StateQueue.front();
			s_StateQueue.pop();
		}
		else {
			s_PrepState = None;
		}
	}

	bool ButtonWrapper::RenderToggle(std::string_view name, const ImVec2& size, bool active, bool displayOnly, const ImU32& colorOn, const ImU32& colorOff)
	{
		ImU32 color = active ? colorOn : colorOff;

		ImGui::PushStyleColor(ImGuiCol_Button, color);
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, color);

		if (ImGui::Button(name.data(), size) && !displayOnly) {
			ImGui::PopStyleColor(2);
			return 1;
		}

		ImGui::PopStyleColor(2);
		return 0;
	}

	bool ButtonWrapper::RenderToggleOut(std::string_view name, const ImVec2& size, bool* active, bool displayOnly, const ImU32& colorOn, const ImU32& colorOff)
	{
		ImU32 color = *active ? colorOn : colorOff;

		ImGui::PushStyleColor(ImGuiCol_Button, color);
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, color);

		if (ImGui::Button(name.data(), size) && !displayOnly) {
			*active = !*active;
			ImGui::PopStyleColor(2);
			return 1;
		}

		ImGui::PopStyleColor(2);
		return 0;
	}

	bool ButtonWrapper::RenderSingle(std::string_view name, const ImVec2& size, bool displayOnly, const ImU32& color)
	{
		ImGui::PushStyleColor(ImGuiCol_Button, color);
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, color);

		if (ImGui::Button(name.data(), size) && !displayOnly) {
			ImGui::PopStyleColor(2);
			return 1;
		}

		if (name == ICON_FA_ARROW_LEFT && ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
			ImGui::PopStyleColor(2);
			return 1;
		}

		ImGui::PopStyleColor(2);
		return 0;
	}

	void ButtonWrapper::RenderFake(std::string_view name, const ImVec2& size, const ImU32& color)
	{
		ImGui::PushStyleColor(ImGuiCol_Button, color);
		ImGui::PushStyleColor(ImGuiCol_ButtonHovered, color);
		ImGui::PushStyleColor(ImGuiCol_ButtonActive, color);
		ImGui::Button(name.data(), size);
		ImGui::PopStyleColor(3);
	}

	bool ListBoxWrapper::Render(std::string_view name, const std::vector<std::string>& items, int& index, const ImVec2& size)
	{
		bool changed = false;
		if (ImGui::BeginListBox(name.data(), size)) {
			if (Selection::Render(items, index)) {
				changed = true;
			}
			ImGui::EndListBox();
		}
		return changed;
	}

	void HelpMarker::Render(std::string_view text)
	{
		ImGui::TextDisabled(ICON_FA_CIRCLE_QUESTION);
		if (ImGui::IsItemHovered()) {
			ImGui::BeginTooltip();
			ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0f);
			ImGui::TextWrapped(text.data());
			ImGui::PopTextWrapPos();
			ImGui::EndTooltip();
		}
	}

}
// ---------------------------------------------------------------------------
// Theme: the player's custom colors (Miscellaneous > Appearance)
// ---------------------------------------------------------------------------
#include "Walnut/FileFormats/json.h"
#include <cstdio>

namespace Theme {

	static const char* const keys[Count] = { "Buttons", "Highlights", "On", "Off", "Background", "Text" };

	static float Clamp01(float v) { return v < 0.0f ? 0.0f : (v > 1.0f ? 1.0f : v); }

	// Recolors a color of ImGui's dark style: each channel keeps the same ratio to the theme color
	// that it had to the default, so the default theme looks exactly like before.
	static ImVec4 Recolor(const ImVec4& base, const ImVec4& from, const ImVec4& to)
	{
		auto channel = [](float b, float f, float t) { return f > 0.0001f ? Clamp01(t * b / f) : t; };
		return ImVec4(channel(base.x, from.x, to.x), channel(base.y, from.y, to.y), channel(base.z, from.z, to.z), base.w);
	}

	void Apply()
	{
		static ImVec4 base[ImGuiCol_COUNT];
		static bool captured = false;
		ImGuiStyle& style = ImGui::GetStyle();
		if (!captured) {
			for (int i = 0; i < ImGuiCol_COUNT; i++) {
				base[i] = style.Colors[i];
			}
			captured = true;
		}

		// Highlights: everything the dark style draws in its blue
		const ImVec4 defaultHighlight = ImGui::ColorConvertU32ToFloat4(defaults[Highlights]);
		const ImVec4 highlight = ImGui::ColorConvertU32ToFloat4(colors[Highlights]);
		static const ImGuiCol highlightCols[] = { ImGuiCol_FrameBg, ImGuiCol_FrameBgHovered, ImGuiCol_FrameBgActive, ImGuiCol_TitleBgActive, ImGuiCol_CheckMark,
			ImGuiCol_SliderGrab, ImGuiCol_SliderGrabActive, ImGuiCol_Button, ImGuiCol_ButtonHovered, ImGuiCol_ButtonActive, ImGuiCol_Header, ImGuiCol_HeaderHovered,
			ImGuiCol_HeaderActive, ImGuiCol_SeparatorHovered, ImGuiCol_SeparatorActive, ImGuiCol_ResizeGrip, ImGuiCol_ResizeGripHovered, ImGuiCol_ResizeGripActive,
			ImGuiCol_Tab, ImGuiCol_TabHovered, ImGuiCol_TabActive, ImGuiCol_TabUnfocused, ImGuiCol_TabUnfocusedActive, ImGuiCol_DockingPreview,
			ImGuiCol_TextSelectedBg, ImGuiCol_NavHighlight };
		for (ImGuiCol col : highlightCols) {
			style.Colors[col] = Recolor(base[col], defaultHighlight, highlight);
		}

		// Background: window, popups, title bars, scrollbars
		const ImVec4 defaultBackground = ImGui::ColorConvertU32ToFloat4(defaults[Background]);
		const ImVec4 background = ImGui::ColorConvertU32ToFloat4(colors[Background]);
		static const ImGuiCol backgroundCols[] = { ImGuiCol_WindowBg, ImGuiCol_PopupBg, ImGuiCol_TitleBg, ImGuiCol_TitleBgCollapsed, ImGuiCol_MenuBarBg,
			ImGuiCol_ScrollbarBg, ImGuiCol_DockingEmptyBg };
		for (ImGuiCol col : backgroundCols) {
			style.Colors[col] = Recolor(base[col], defaultBackground, background);
		}

		// Text
		const ImVec4 text = ImGui::ColorConvertU32ToFloat4(colors[Text]);
		style.Colors[ImGuiCol_Text] = ImVec4(text.x, text.y, text.z, base[ImGuiCol_Text].w);
		style.Colors[ImGuiCol_TextDisabled] = ImVec4(text.x * 0.5f, text.y * 0.5f, text.z * 0.5f, base[ImGuiCol_TextDisabled].w);
	}

	static std::string ToHex(ImU32 color)
	{
		char buf[8];
		snprintf(buf, sizeof(buf), "#%02X%02X%02X", (color >> IM_COL32_R_SHIFT) & 0xFF, (color >> IM_COL32_G_SHIFT) & 0xFF, (color >> IM_COL32_B_SHIFT) & 0xFF);
		return buf;
	}

	static bool FromHex(const std::string& hex, ImU32& out)
	{
		unsigned int r, g, b;
		if (hex.size() != 7 || hex[0] != '#' || sscanf_s(hex.c_str() + 1, "%02x%02x%02x", &r, &g, &b) != 3) {
			return false;
		}
		out = IM_COL32(r, g, b, 255);
		return true;
	}

	void Load(const std::string& settingsPath)
	{
		Walnut::JSONBuilder builder = Walnut::JSONBuilder::FromFile(settingsPath);
		rapidjson::Document& doc = builder.GetDocument();
		if (doc.IsObject() && doc.HasMember("Theme Colors") && doc["Theme Colors"].IsObject()) {
			const rapidjson::Value& saved = doc["Theme Colors"];
			for (int i = 0; i < Count; i++) {
				if (saved.HasMember(keys[i]) && saved[keys[i]].IsString()) {
					FromHex(saved[keys[i]].GetString(), colors[i]);
				}
			}
		}
		Apply();
	}

	void Save(const std::string& settingsPath)
	{
		Walnut::JSONBuilder builder = Walnut::JSONBuilder::FromFile(settingsPath);
		rapidjson::Document& doc = builder.GetDocument();
		if (!doc.IsObject()) {
			doc.SetObject();
		}
		rapidjson::Value saved(rapidjson::kObjectType);
		for (int i = 0; i < Count; i++) {
			const std::string hex = ToHex(colors[i]);
			rapidjson::Value key(keys[i], builder.GetAllocator());
			rapidjson::Value value(hex.c_str(), static_cast<rapidjson::SizeType>(hex.size()), builder.GetAllocator());
			saved.AddMember(key, value, builder.GetAllocator());
		}
		if (doc.HasMember("Theme Colors")) {
			doc["Theme Colors"] = saved;
		}
		else {
			doc.AddMember("Theme Colors", saved, builder.GetAllocator());
		}
		builder.SaveToFile(settingsPath);
	}
}
