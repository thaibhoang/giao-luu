module ApplicationHelper
  GENDER_LABELS = {
    "male" => "Nam",
    "female" => "Nữ",
    "other" => "Khác",
    "prefer_not_to_say" => "Không muốn tiết lộ"
  }.freeze

  BADMINTON_SKILL_LABELS = {
    "beginner" => "Mới bắt đầu",
    "intermediate" => "Trung cấp",
    "advanced" => "Khá",
    "competitive" => "Thi đấu"
  }.freeze

  def gender_label(value)
    GENDER_LABELS[value] || "—"
  end

  def badminton_skill_label(value)
    BADMINTON_SKILL_LABELS[value] || value || "—"
  end
end
