module ApplicationHelper
  # Render inline SVG từ app/assets/images/<name>.svg
  # Hỗ trợ currentColor, có thể truyền class CSS.
  def inline_svg(name, css_class: "w-5 h-5", **attrs)
    svg_path = Rails.root.join("app/assets/images/#{name}.svg")
    return "" unless svg_path.exist?

    svg_content = svg_path.read
    # Inject class và các attributes vào thẻ <svg>
    attr_str = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
    svg_content.sub(/<svg/, "<svg class=\"#{css_class}\" #{attr_str} aria-hidden=\"true\"")
               .html_safe
  end

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
