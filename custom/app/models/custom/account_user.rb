# frozen_string_literal: true

module Custom::AccountUser
  def agent?
    super || supervisor?
  end

  def permissions
    return %w[supervisor agent] if supervisor?

    super
  end
end
