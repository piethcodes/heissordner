# Specify your image location and printer name here
$path = ""
$PrinterName  = "Microsoft Print to PDF"

[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
Get-ChildItem -recurse ($path) -include @("*.png", "*.jpg") |
ForEach-Object {
	# Read the image from the file
    $ImageByteArray = [System.IO.File]::ReadAllBytes($_)
    $ImageConverter = New-Object System.Drawing.ImageConverter
    [System.Drawing.Bitmap] $Image = $ImageConverter.ConvertFrom($ImageByteArray)
	# rotate image to portrait
	if ($Image.Width -gt $Image.Height) { 
		$image.rotateflip("Rotate90FlipNone") 
	}


	Add-Type -AssemblyName System.Drawing
	$PrintDocument = New-Object System.Drawing.Printing.PrintDocument
	$PrintDocument.PrinterSettings.PrinterName = $PrinterName
	$PrintDocument.DefaultPageSettings.PaperSize = `
		$PrintDocument.PrinterSettings.PaperSizes | where Kind -eq "A4"
	$PrintDocument.DefaultPageSettings.Landscape = $false
	$PrintDocument.DocumentName = $DocumentName

	$PrintDocument.add_PrintPage({
		
		param($Sender, $PrintPageEventArgs)
		  
		$PAWidth  = $PrintPageEventArgs.PageSettings.PrintableArea.Width
		$PAHeight = $PrintPageEventArgs.PageSettings.PrintableArea.Height
		
		$ImageWidthToHeight = $Image.Width / $Image.Height
		$PAWidthToHeight    = $PAWidth / $PAHeight
		
		# Calculate the image size 
		$ScaledImageWidth  = if ($ImageWidthToHeight -ge $PAWidthToHeight) { $PAWidth } `
							 else { $PAHeight * $ImageWidthToHeight }
		$ScaledImageHeight = if ($ImageWidthToHeight -ge $PAWidthToHeight) { $PAWidth / $ImageWidthToHeight } `
							 else { $PAHeight }

		# Coordinates of the top left corner of the image
		$RectTopLeftX = ($PAWidth  - $ScaledImageWidth)  / 2
		$RectTopLeftY = ($PAHeight - $ScaledImageHeight) / 2

		$Rectangle = [System.Drawing.RectangleF]::new( `
			$RectTopLeftX, $RectTopLeftY, $ScaledImageWidth, $ScaledImageHeight)

		# "Draw" image on the page
		$PrintPageEventArgs.Graphics.DrawImage($Image, $Rectangle)
	})

	$PrintDocument.Print()
}