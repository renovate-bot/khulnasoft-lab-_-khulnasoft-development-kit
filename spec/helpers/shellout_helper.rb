# frozen_string_literal: true

module ShelloutHelper
  def allow_kdk_shellout
    allow(KDK::Shellout).to receive(:new)
  end

  def allow_kdk_shellout_command(*args, **kwargs)
    allow_kdk_shellout.with(*args, **kwargs)
  end

  def expect_kdk_shellout
    expect(KDK::Shellout).to receive(:new)
  end

  def expect_kdk_shellout_command(*args, **kwargs)
    expect_kdk_shellout.with(*args, **kwargs)
  end

  def expect_no_kdk_shellout
    expect(KDK::Shellout).not_to receive(:new)
  end

  def kdk_shellout_double(**kwargs)
    instance_double(KDK::Shellout, **kwargs)
  end
end
