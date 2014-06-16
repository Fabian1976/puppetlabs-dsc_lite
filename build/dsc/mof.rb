module Dsc
  class Mof

    def initialize(options)
      @qualifiers_folder            = options[:qualifiers_folder]

      @dmtf_qualifiers_folder       = options[:dmtf_qualifiers_folder]
      @base_qualifiers_folder       = options[:base_qualifiers_folder]
      @dsc_modules_folder           = options[:dsc_modules_folder]

      @dmtf_cim_schema_version      = options[:dmtf_cim_schema_version]

      @dmtf_cim_mof                 = "#{@dmtf_qualifiers_folder}/cim_schema_#{@dmtf_cim_schema_version}.mof"
      @dmtf_qualifiers_mof          = "#{@dmtf_qualifiers_folder}/qualifiers.mof"
      @dmtf_qualifiers_optional_mof = "#{@dmtf_qualifiers_folder}/qualifiers_optional.mof"

      @dsc_modules_mof              = "#{@qualifiers_folder}/dsc_modules.mof"
      @dsc_base_mof                 = "#{@qualifiers_folder}/base.mof"

      @dsc_mof_file_pathes = nil
    end

    def dsc_mof_file_pathes
      @dsc_mof_file_pathes ||= find_mofs(@dsc_modules_folder)
    end

    def dsc_results
      all_result.select{|k,v| dsc_mof_file_pathes.include?(k)}
    end

    def all_result
      create_index_mof(@dsc_modules_mof, dsc_mof_file_pathes)

      # convert files to unix format
      dsc_mof_file_pathes.each do |file|
        %x{dos2unix #{file}}
      end

      # find all mof files in base_qualifiers_folder
      base_mof_file_pathes = find_mofs(@base_qualifiers_folder)
      # generate base mof import file
      create_index_mof(@dsc_base_mof, base_mof_file_pathes)


      moffiles, options = MOF::Parser.argv_handler "moflint", ARGV
      options[:style] ||= :cim;
      options[:includes] ||= []

      moffiles.unshift @dsc_modules_mof unless moffiles.include? @dsc_modules_mof
      moffiles.unshift @dsc_base_mof unless moffiles.include? @dsc_custom_mof
      moffiles.unshift @dmtf_cim_mof unless moffiles.include? @dmtf_cim_mof
      moffiles.unshift @dmtf_qualifiers_optional_mof unless moffiles.include? @dmtf_qualifiers_optional_mof
      moffiles.unshift @dmtf_qualifiers_mof unless moffiles.include? @dmtf_qualifiers_mof

      parser = MOF::Parser.new options

      begin
        result = parser.parse moffiles
      rescue Exception => e
        parser.error_handler e
        exit 1
      end
      # return mof result
      result
    end



    private
    
    def create_index_mof(index_mof_file_name, mofs)
      File.open(index_mof_file_name, 'w') do |file|
        mofs.each{|mof_path| file.write("#pragma include (\"#{mof_path}\")\n") }
      end
    end

    def find_mofs(folder)
      mof_file_pathes = []
      if File.exist?(folder)
        Find.find(folder) do |path|
          mof_file_pathes << path if path =~ /.*\.mof$/
        end
      end
      mof_file_pathes
    end

  end
end
