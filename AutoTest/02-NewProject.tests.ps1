Describe 'New-Project' {
    Context 'TDD' {
        BeforeAll {
            $project_name = "Hello"
            $repo_folder = Resolve-Path '../'
            $new_folder = "$repo_folder/$project_name"
        }
        It 'Already exists' {
            New-Item -ItemType Directory -Path $new_folder
            $res = New-Project  $project_name
            Remove-Item -Path $new_folder
            $res | Should -Be  @($null, "$project_name already exists")
        }  
        It 'Create New Project' {           
            $res = New-Project  $project_name
            $res | Should -Be  @($null, $project_name)
        }

    }
}