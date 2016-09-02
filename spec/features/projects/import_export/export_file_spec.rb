require 'spec_helper'

# Integration test that exports a file using the Import/EXport feature
# It looks up for any sensitive word inside the JSON, so if a sensitive word is found
# we''l have to either include it adding the model containing it to the +safe_list+
# or make sure the attribute is blacklisted in the +import_export.yml+ configuration
feature 'project export', feature: true, js: true do
  include Select2Helper
  include ExportFileHelper

  let(:user) { create(:admin) }
  let(:export_path) { "#{Dir::tmpdir}/import_file_spec" }
  let(:config_hash) { YAML.load_file(Gitlab::ImportExport.config_file).deep_stringify_keys }

  let(:sensitive_words) { %w[pass secret token key] }
  let(:safe_list) do
    {
      token: [ProjectHook, Ci::Trigger],
      key: [Project, Ci::Variable, :yaml_variables]
    }
  end
  let(:safe_hashes) { { yaml_variables: %w[key value public] } }

  let(:project) { setup_project }

  background do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'admin user' do
    before do
      login_as(user)
    end

    scenario 'exports a project successfully' do
      visit edit_namespace_project_path(project.namespace, project)

      expect(page).to have_content('Export project')

      click_link 'Export project'

      visit edit_namespace_project_path(project.namespace, project)

      expect(page).to have_content('Download export')

      in_directory_with_expanded_export(project) do |exit_status, tmpdir|
        expect(exit_status).to eq(0)

        project_json_path = File.join(tmpdir, 'project.json')
        expect(File).to exist(project_json_path)

        project_hash = JSON.parse(IO.read(project_json_path))

        sensitive_words.each do |sensitive_word|
          found = find_sensitive_attributes(sensitive_word, project_hash)

          expect(found).to be_nil, "Found a new sensitive word <#{found.try(:key_found)}>, which is part of the hash #{found.try(:parent)}"
        end
      end
    end
  end
end
