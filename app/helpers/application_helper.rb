module ApplicationHelper
  def priority_badge(priority)
    classes = {
      "high" => "bg-rose-50 text-rose-700 ring-rose-600/20",
      "medium" => "bg-amber-50 text-amber-700 ring-amber-600/20",
      "low" => "bg-sky-50 text-sky-700 ring-sky-600/20"
    }
    content_tag :span, priority.capitalize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes.fetch(priority, classes['low'])}"
  end

  def plan_status_badge(status)
    classes = {
      "draft" => "bg-violet-50 text-violet-700 ring-violet-600/20",
      "approved" => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
      "rejected" => "bg-slate-100 text-slate-600 ring-slate-500/20"
    }
    content_tag :span, status.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes.fetch(status)}"
  end

  def document_status_badge(status)
    classes = {
      "pending" => "bg-amber-50 text-amber-700 ring-amber-600/20",
      "processing" => "bg-sky-50 text-sky-700 ring-sky-600/20",
      "ready" => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
      "failed" => "bg-rose-50 text-rose-700 ring-rose-600/20"
    }
    content_tag :span, status.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes.fetch(status)}"
  end

  def data_import_status_badge(status)
    classes = {
      "pending" => "bg-slate-100 text-slate-600 ring-slate-500/20",
      "previewed" => "bg-sky-50 text-sky-700 ring-sky-600/20",
      "invalid" => "bg-amber-50 text-amber-700 ring-amber-600/20",
      "applying" => "bg-violet-50 text-violet-700 ring-violet-600/20",
      "completed" => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
      "failed" => "bg-rose-50 text-rose-700 ring-rose-600/20"
    }
    content_tag :span, status.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes.fetch(status)}"
  end

  def outcome_status_badge(status)
    classes = {
      "in_progress" => "bg-amber-50 text-amber-700 ring-amber-600/20",
      "completed" => "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
    }
    content_tag :span, status.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes.fetch(status)}"
  end

  def effectiveness_badge(effectiveness)
    return content_tag(:span, "Not rated", class: "text-xs font-semibold text-slate-400") if effectiveness.blank?

    classes = effectiveness == "effective" ? "bg-emerald-50 text-emerald-700" : "bg-rose-50 text-rose-700"
    content_tag :span, effectiveness.humanize, class: "inline-flex rounded-full px-2.5 py-1 text-xs font-bold #{classes}"
  end

  def mastery_change_label(before_score, after_score)
    return "—" if before_score.blank? || after_score.blank?

    change = after_score.to_f - before_score.to_f
    "#{change.positive? ? '+' : ''}#{change.round}%"
  end

  def initials(name)
    name.split.filter_map { |part| part.first }.first(2).join.upcase
  end
end
