$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

function Is-Equal($a, $b) {
    return @(Compare-Object -ReferenceObject $a -DifferenceObject $b -PassThru).Length -eq 0
}

function Have-AnyGotPropertyValue($x, $propery, $value) {
    $x | select -ExpandProperty $propery | foreach {
        if ($_ -eq $value) {
            return $true
        }
    }
    return $false
}

Describe "Outlook" {

    Context "Mail exists" {
        BeforeAll {
            Mock Get-Date { return [DateTime]::Parse("2015-01-01 14:15") }
            Mock Forward-Mail {}
            Mock Save-ForwardedMail {}
            Mock Get-Email {
                $mails = @()
                $mails += [PsCustomObject]@{EntryId="abc123";Subject="Test title 1";MessageClass="IPM.Note"}
                $mails += [PsCustomObject]@{EntryId="def456";Subject="Test title 2";MessageClass="IPM.Note"}
                $mails += [PsCustomObject]@{EntryId="ghi789";Subject="Test title 3";MessageClass="IPM.Note"}
                $mails += [PsCustomObject]@{EntryId="jkl012";Subject="Test title 4";MessageClass="IPM.Schedule.Meeting.Request"}
                return $mails
            }
            Mock Is-MailForwarded { 
                param($EntryId)
                return $EntryId -eq "def456"
            }
            Send-NewMailAsForward -To "johan@classon.eu" -Prefix "Test Prefix"
        }

        It "forwards mail to the correct recipient" {
            Assert-MockCalled Forward-Mail -ParameterFilter { $To -eq "johan@classon.eu" }
        }

        It "forwards mail with the correct subject" {
            Assert-MockCalled Forward-Mail -ParameterFilter { $Prefix -eq "Test Prefix" }
        }

        It "does not forward meeting requests" {
            Assert-MockCalled Forward-Mail -ParameterFilter { -not (Have-AnyGotPropertyValue $Mails "MessageClass" "IPM.Schedule.Meeting.Request") }
        }

        It "forwards mail with the correct content" {
            Assert-MockCalled Forward-Mail -ParameterFilter { Is-Equal $Mails.Subject "Test title 1","Test title 3" } 
        }

        It "gets email that has been recievied within 24h" {
            Assert-MockCalled Get-Email -Exactly -Times 1 -ParameterFilter { $RestrictFilter -eq "[ReceivedTime] > '12/31/2014 2:15 PM'" }
        }

        It "records which mails that has been forwarded" {
            Assert-MockCalled Save-ForwardedMail -Times 2 -Exactly
            Assert-MockCalled Save-ForwardedMail -ParameterFilter { $EntryId -eq "abc123" }
            Assert-MockCalled Save-ForwardedMail -ParameterFilter { $EntryId -eq "ghi789" }
        }
    }

    Context "Mail does not exist" {
        BeforeAll {
            Mock Get-Date { return [DateTime]::Parse("2015-01-01 14:15") }
            Mock Forward-Mail {}
            Mock Save-ForwardedMail {}
            Mock Get-Email {
                $mails = @()
                return $mails
            }
            Send-NewMailAsForward -To "johan@classon.eu" -Prefix "Test Prefix"
        }

        It "should not forward any mail" {
            Assert-MockCalled Forward-Mail -Times 0 -Exactly
        }

        It "should not record any forwarded mails" {
            Assert-MockCalled Save-ForwardedMail -Times 0 -Exactly
        }
    }
}
