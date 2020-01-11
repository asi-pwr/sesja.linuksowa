# frozen_string_literal: true

class SesjaLinuksowa < Sinatra::Application
  configure do
    enable :sessions

    # Nie zapomnij zmienić tego!
    set edition: "17"
    set :hide_talk_submission_form, true

    register Sinatra::R18n
    R18n::I18n.default = "pl"
    set :locales, %w[pl en]
    set :default_locale, 'pl'
    helpers do
      def locale
        @locale || settings.default_locale
      end
    end

    register Sinatra::AssetPipeline
    if defined?(RailsAssets)
      RailsAssets.load_paths.each do |path|
        settings.sprockets.append_path(path)
      end
    end

    register Sinatra::Partial
    set :partial_template_engine, :haml

    set :haml, format: :html5

    set default_to: "sesja@linuksowa.pl"
    if development?
      set :email_options,
          via: :smtp,
          via_options: {
            address: "localhost",
            port: "1025"
          }
    else
      set :email_options,
          from: "asiwww@tramwaj.asi.pwr.wroc.pl"
    end
  end

  if settings.edition.empty?
    abort("Edycja Sesji nie jest ustawiona, zajrzyj do pliku sesja.rb!")
  end

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path(__dir__)
  end

  get '/' do
    redirect "/pl"
  end

  before('/:locale/*') { @locale = params[:locale] }

  get '/:locale/agenda' do
    haml :agenda, locals: { edition: settings.edition, hide_talk_submission_form: settings.hide_talk_submission_form }, layout: false
  end

  get '/:locale/?' do
    haml :index, locals: { edition: settings.edition, hide_talk_submission_form: settings.hide_talk_submission_form }
  end

  post '/' do
    # Antispam filter lol
    redirect '/' unless params[:email].nil?

    require 'pony'
    Pony.options = settings.email_options

    subject = "#{params[:name]} <#{params[:adres]}>"
    body = ""

    if params[:abstract]
      Pony.subject_prefix("[PRELEKCJA] ")
      body << "Temat: #{params[:content]}\n"
      body << "Abstrakt: #{params[:abstract]}\n"
      body << "Długość (min): #{params[:duration]}\n"
      body << "Opis na stronę: #{params[:description]}\n"
      body << "Opis prelegenta: #{params[:aboutyou]}\n"
    else
      Pony.subject_prefix("[FORMULARZ KONTAKTOWY] ")
      body = params[:content].to_s
    end
    Pony.mail(to: settings.default_to, subject: subject, body: body)
    redirect '/'
  end

  not_found do
    haml :notfound
  end

  error do
    haml :error
  end
end
