require_relative '../support/job_buffer'

class TranslatedHelloJob < ActiveJob::Base
  def perform(greeter = "David")
    translations = { en: 'hello', de: 'hallo' }
    hello        = translations[I18n.locale]

    JobBuffer.add("#{greeter} says #{hello}")
  end
end
