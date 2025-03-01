Describe 'PR-WF' {
    Context 'auto_vote' {
        It 'Test-OK' {
            Set-AutoTestOn
            $res = Send-AMLFiles 'admin' @('src\Test-AML\T03-TestOK.xml')
            $res | Should -Be @('Aras.IOM.Innovator', 'OK')
        }
        It 'Test-auto_vote' {
            Set-AutoTestOff
            $res = Send-AMLFiles 'jon.hodge' @('src\Test-AML\T02-PR-WF-Test-AutoVote.xml')
            $res | Should -Be @('Aras.IOM.Innovator', 'OK')
        }

    }
}