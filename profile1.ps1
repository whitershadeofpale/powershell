# Write-Host "Profile folder : $env:USERPROFILE\Documents" -ForegroundColor DarkGray
# Write-Host "Old profile file : D:\Metin\docs\WindowsPowerShell\profile.ps1 which does not exits in new installation." -ForegroundColor DarkGray
# Write-Host "Current profile file is `$profile variable and the value is $profile" -ForegroundColor Gray
New-Alias reboot Restart-Computer
New-Alias poweroff Stop-Computer
# New-Alias -Name "n" "D:\Smalltools\Notepad2.exe"
New-Alias -Name "n" "code"
New-Alias -Name "uptime" Get-Uptime
New-Alias less "C:\Program Files\Git\usr\bin\less.exe"
New-Alias -Name we "Get-WinEvent"

$tips = "D:\Metin\tips"
# $gdrv = "C:\Users\metin.ozmener\Google Drive"

# Exchange server OWA logs
$excowa = "\\exchange2019\c$\inetpub\logs\LogFiles\W3SVC1"

# Exchange server Receive logs
$excrcv = "\\exchange2019\c$\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpReceive"

# Exchange server Send logs
$excsnd = "\\exchange2019\c$\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\Hub\ProtocolLog\SmtpSend"

function ks {
	Get-Process Spotify,gamebar -ea silent | Stop-Process -Force
}

function Show-Quote { 
 
# List of Quotes added in to Array 
[string[]]$quoteList =  
"Do Good, Be Good, Be one.", 
"Life is like a flowing river of opportunities. It's up to you to stand up with a bucket or with a spoon.", 
"All the art of living lies in a fine mingling of letting go and holding on. - Henry Ellis", 
"You are not YET complete. You have no right to judge yourself because you are still work in progress !", 
"Wise men talk because they have something to say, Fools, because they have to say something. - Plato", 
"Keep dreaming guys, they do come true. - Divine Arcanas (The Hermit)", 
"If you are going to be thinking, you may as well think big. - Donald Trump", 
"They told me, You Can't, I replied I Will. Divine Arcanas (The Hermit)", 
"People who are crazy enough to think they can change the world, are the ones who do. - Apple Computers", 
"When people underestimate you, there's a power in you to prove they're wrong. Not to prove them, but to prove yourself.", 
"Anyone who judges you by the kind of car you drive or shoes you wear , isn t someone worth impressing.", 
"When things didn't go as you planned, don't be let down. Make NEW plans. The sun doesn't stop SHINNING just because of dark clouds ", 
"You are never given a desire without also being given the power to make it true.", 
"Do the hard jobs first. The easy jobs will take care of themselves. - Dale Carnegie", 
"Success is doing ordinary things extraordinarily well. - Jim Rohn", 
"Success is the sum of small efforts, repeated day in and day out. - Robert Collier", 
"Attitude is a little thing that makes a big difference. - Winston Churchill", 
"Flaming enthusiasm, backed up by horse sense and persistence, is the quality that most frequently makes for success. - Dale Carnegie", 
"The three great essentials to achieve anything worthwhile are, first, hard work; second, stick-to-itiveness; third, common sense. - Thomas A. Edison", 
"A good leader takes a little more than his share of the blame, a little less than his share of the credit. - Arnold H. Glasgow", 
"Failure is simply the opportunity to begin again, this time more intelligently. - Henry Ford", 
"What great thing would you attempt if you knew you could not fail? - Robert H. Schuller", 
"All the art of living lies in a fine mingling of letting go and holding on. - Henry Ellis",
"The biggest communication problem is we don't listen to understand, we listen to reply - Reddit",
"Akil, kisiye sermayedir. - Turk atasozu",
"Akil malin en kiymetlisidir. - Cerkez atasozu",
"Akil ve bilim, aydinlik kesimdedir. Din, imansa karanlik kesimde. Aklin, bilimin olculeri bellidir. Gozlem vardir, deney vardir, nesnellik vardir. Yolu isiklandiran da bunlar. Din ve imanda ise bunlar yoktur. - Turan Dursun",
"Akil, yalniz dogrulukta bulunur. - Goethe",
"Akilli kisiyi sirtinda tasisan dahi yuk gelmez . - Cerkez atasozu",
"Akli olmayan fakirdir. - Cerkez atasozu",
"Deli bile konusuncaya kadar akilli zannedilir. - Cerkez atasozu",
"Delinin beyi olmaktansa akillinin kolesi olmak daha iyidir. - Cerkez atasozu",
"Duygunun yaninda akil daima adi kalir. - Honor de Balzac",
"Hayal gucu, ereksiyon halindeki zekadir. - Victor Hugo",
"Kadinin el mahareti aklini gosterir. - Cerkez atasozu",
"Kusu yukselten kanat,insan  yukselten akildir. - Cerkez atasozu",
"People often say that motivation doesn't last. Well, neither does bathing -- that's why we recommend it daily. -Zig Ziglar",
"Someday is not a day of the week. -Denise Brennan-Nelson",
"Hire character. Train skill. -Peter Schutz",
"Your time is limited, so don't waste it living someone else's life. -Steve Jobs",
"Sales are contingent upon the attitude of the salesman -- not the attitude of the prospect. -W. Clement Stone",
"Everyone lives by selling something. -Robert Louis Stevenson",
"If you are not taking care of your customer, your competitor will. -Bob Hooey",
"The golden rule for every businessman is this: Put yourself in your customer's place. -Orison Swett Marden",
"If you cannot do great things, do small things in a great way. -Napoleon HillMotivational quote by Napoleon Hill",
"The best leaders are those most interested in surrounding themselves with assistants and associates smarter than they are. They are frank in admitting this and are willing to pay for such talents. -Antos Parrish",
"Beware of monotony; it's the mother of all the deadly sins. -Edith Wharton",
"Nothing is really work unless you would rather be doing something else. -J.M. Barrie",
"Without a customer, you don't have a business -- all you have is a hobby. -Don Peppers",
"To be most effective in sales today, it's imperative to drop your 'sales' mentality and start working with your prospects as if they've already hired you. -Jill Konrath",
"Pretend that every single person you meet has a sign around his or her neck that says, 'Make me feel important.' Not only will you succeed in sales, you will succeed in life. -Mary Kay Ash",
"It's not just about being better. It's about being different. You need to give people a reason to choose your business. -Tom Abbott",
"Being good in business is the most fascinating kind of art. Making money is art and working is art and good business is the best art. -Andy Warhol",
"Be patient with yourself. Self-growth is tender; it's holy ground. There's no greater investment. -Stephen Covey",
"Without hustle, talent will only carry you so far. -Gary Vaynerchuk",
"Working hard for something we don't care about is called stressed; working hard for something we love is called passion. -Simon Sinek",
"I'd rather regret the things I've done than regret the things I haven't done. -Lucille BallMotivational quote by Lucille Ball",
"I didn't get there by wishing for it or hoping for it, but by working for it. -Est e Lauder",
"Always do your best. What you plant now, you will harvest later. -Og Mandino",
"You're in the swing of things now. Here are a few quotes about overcoming challenges for some Tuesday inspiration.",
"The key to life is accepting challenges. Once someone stops doing this, he's dead. -Bette Davis",
"Move out of your comfort zone. You can only grow if you are willing to feel awkward and uncomfortable when you try something new. -Brian Tracy",
"Challenges are what make life interesting and overcoming them is what makes life meaningful. -Joshua J. MarineMotivational quote by Joshua J. Marine",
"Don't let the fear of losing be greater than the excitement of winning. -Robert Kiyosaki",
"How dare you settle for less when the world has made it so easy for you to be remarkable? -Seth Godin",
"Whoa, you're halfway there! Take a look at these quotes about perseverance for the motivation you need to work through the Wednesday afternoon slump.",
"Energy and persistence conquer all things. -Benjamin Franklin",
"Perseverance is failing 19 times and succeeding the 20th. -Julie Andrews",
"Grit is that  extra something' that separates the most successful people from the rest. It's the passion, perseverance, and stamina that we must channel in order to stick with our dreams until they become a reality. -Travis BradberryMotivational quote by Travis Bradberry",
"Failure after long perseverance is much grander than never to have a striving good enough to be called a failure. -George Eliot",
"The secret of joy in work is contained in one word -- excellence. To know how to do something well is to enjoy it. -Pearl Buck",
"You're in the final stretch of the week. These quotes about success are sure to power you through until the weekend.",
"Develop success from failures. Discouragement and failure are two of the surest stepping stones to success. -Dale Carnegie",
"Action is the foundational key to all success. -Pablo Picasso",
"The ladder of success is best climbed by stepping on the rungs of opportunity. -Ayn RandMotivational quote by Ayn Rand",
"Formula for success: rise early, work hard, strike oil. -J. Paul Getty",
"The difference between a successful person and others is not a lack of strength, not a lack of knowledge, but rather a lack of will. -Vince Lombardi",
"It's Friday, or should I say Fri-yay! Pat yourself on the back for the hard work you've put in all week. Here are some determination quotes to help you cross the finish line.",
"Obstacles are those frightful things you see when you take your eyes off your goal. -Henry Ford",
"It is your determination and persistence that will make you a successful person. -Kenneth J Hutchins",
"You can waste your lives drawing lines. Or you can live your life crossing them. -Shonda RhimesMotivational quote by Shonda Rhimes",
"Determine that the thing can and shall be done, and then we shall find the way. -Abraham Lincoln",
"Done is better than perfect. -Sheryl Sandberg",
"Don't ask if your dream is crazy, ask if it's crazy enough. -Lena Waithe",
"The act of doing something un-does the fear. -Shonda Rhimes",
"Be poor, humble and driven (PhD). Don't be afraid to shift or pivot. -Alex Rodriguez",
"#1 make good decisions, #2 everything else. -Rand Fishkin"

        #Choosing One Randonm Quote     
        $randomQuote = $quoteList | Get-Random -Count 1 
 
        # Writing Quote 
        "`n" 
        Write-host $randomQuote -ForegroundColor Yellow 
        "`n" 
}

Show-Quote
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

function Prompt
{
    $prompt_path = Get-Location
    $prompt_right = Get-Date -Format " dd, ddd | HH:mm "
    $winlogo = [char]0xE70F
    $prompt_char = [char]0x276f
    $elevated = [char]0xF79F

    $battery = gcim Win32_Battery
    $BatteryGlyph = ""

    $OS=gwmi Win32_OperatingSystem
    # display remaining free RAM and free SWAP
    $meminfo = "{0:N0}" -f ($OS.FreePhysicalMemory/1MB)
    $meminfo += " / "
    $meminfo += "{0:N0}" -f ($OS.FreeSpaceInPagingFiles/1MB)
    $meminfo = " ($meminfo) "

    if ($battery.Status -ne "OK") { $BatteryGlyph = [char]0xf12a } # EXCLAMATIN before percentage; which may mean there is an aging problem with the battery

    if ($battery.BatteryStatus -eq 1) { $BatteryGlyph += [char]0xf063 }
    elseif ($battery.BatteryStatus -eq 2) { $BatteryGlyph += [char]0xf062 }

    if ($battery.EstimatedChargeRemaining -ge 80) { $bcolor = "green"}
    elseif ($battery.EstimatedChargeRemaining -ge 50) { $bcolor = "cyan"}
    elseif ($battery.EstimatedChargeRemaining -gt 30) { $bcolor = "blue"}
    else { $bcolor = "red"}
    $prompt_battery = "[$BatteryGlyph $($battery.EstimatedChargeRemaining)] "

    # leftmost: Path
    Write-Host $prompt_path -ForegroundColor Cyan -NoNewline
    $current_Y = [Console]::CursorTop
    $console_width = [Console]::BufferWidth
    [Console]::SetCursorPosition($console_width-($prompt_battery.Length + $prompt_right.length + $meminfo.length),$current_Y)

    # Rightmost: Battery + Memory + date&time
    Write-Host $prompt_battery -ForegroundColor $bcolor -NoNewline
    Write-Host $meminfo -ForegroundColor DarkYellow -NoNewline
    Write-Host $prompt_right -ForegroundColor Gray -BackgroundColor DarkMagenta

    if ((Get-History).Length -gt 0)
    {
        $LastExecutionTime = [long]((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).TotalMilliSeconds
    }
    else
    {
        $LastExecutionTime = "0"
    }

    if ($LastExecutionTime -gt 3600000) {
        $LastExecutionTime = $LastExecutionTime/3600000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "($Duration hour) "
    }
    elseif ($LastExecutionTime -gt 60000) {
        $LastExecutionTime = $LastExecutionTime/60000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "($Duration min) "
    }
    elseif ($LastExecutionTime -gt 2000)
    {
        $LastExecutionTime = $LastExecutionTime/1000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "($Duration sec) "
    }
    elseif ($LastExecutionTime -gt 10) {
        $Duration = "($LastExecutionTime ms) "
    }
    else { $Duration ="" }
    
    # second line: elevation + duration + prompt
    if ((New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            Write-Host "$elevated " -ForegroundColor White -BackgroundColor Red -NoNewline
            Write-Host "$Duration" -ForegroundColor Magenta -NoNewline
            Write-Host "$winlogo $prompt_char" -ForegroundColor White -NoNewline
        }
    else {
        Write-Host "$Duration" -ForegroundColor Magenta -NoNewline
        Write-Host "$winlogo $prompt_char" -ForegroundColor White -NoNewline
    }

    Set-PSReadLineOption -PromptText "$winlogo $prompt_char "

    # if required to diplay path in the title bar:
    $host.ui.rawui.WindowTitle = (Get-Location)
    return " "
}