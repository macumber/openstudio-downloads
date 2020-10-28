# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'net/http'
require 'openssl'
require 'json'

# start the measure
class OpenStudioDownloads < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'OpenStudio Downloads'
  end

  # human readable description
  def description
    return 'Outputs number of downloads of last 5 releases'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    num_releases = OpenStudio::Measure::OSArgument::makeIntegerArgument('num_releases',true)
    num_releases.setDisplayName('Number of releases')
    num_releases.setDefaultValue(5)
    args << num_releases

    chs = OpenStudio::StringVector.new
    chs << 'Application'
    chs << 'SketchUp Plug-in'
    repo = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('repo',chs)
    repo.setDisplayName('Repo to check')
    repo.setDefaultValue('Application')
    args << repo

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    num_releases = runner.getIntegerArgumentValue('num_releases',user_arguments)
    repo = runner.getStringArgumentValue('repo',user_arguments)

    uri = URI('https://api.github.com/repos/openstudiocoalition/OpenStudioApplication/releases')
    if repo == 'SketchUp Plug-in'
      uri = URI('https://api.github.com/repos/openstudiocoalition/openstudio-sketchup-plugin/releases')
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.get(uri).body
    releases = JSON::parse(response)

    n = 1
    releases.each do |release|
      release_name = release['name']
      runner.registerInfo(release_name)
      release['assets'].each do |asset|
        asset_name = asset['name']
        download_count = asset['download_count']
        runner.registerInfo("#{asset_name} = #{download_count}")
        runner.registerValue("#{release_name}.#{asset_name}", download_count, "downloads")
      end

      n += 1
      break if n > num_releases
    end


    return true
  end
end

# register the measure to be used by the application
OpenStudioDownloads.new.registerWithApplication
