function Create-TermSets($termsXML, $group, $termStore, $Context) {
 
    $termSets = $termsXML.Descendants("TermSet") | Where { $_.Parent.Parent.Attribute("Name").Value -eq $group.Name }
 
    foreach ($termSetNode in $termSets)
    {
        $errorOccurred = $false
        $name = $termSetNode.Attribute("Name").Value;
        $id = [System.Guid]::Parse($termSetNode.Attribute("Id").Value);
        $description = $termSetNode.Attribute("Description").Value;
        $customSortOrder = $termSetNode.Attribute("CustomSortOrder").Value;
        Write-host "Processing TermSet $name ... " -NoNewLine
         
        $termSet = $termStore.GetTermSet($id);
        $spcontext.Load($termSet);
  
        try
        {
            $Context.ExecuteQuery();
        }
        catch
        {
            Write-host "Error while finding if " $name " termset already exists. " $_.Exception.Message -ForegroundColor Red
            exit 1
        }
         
        if ($termSet.ServerObjectIsNull)
        {
            $termSet = $group.CreateTermSet($name, $id, $termStore.DefaultLanguage);
            $termSet.Description = $description;
 
            if($customSortOrder -ne $null)
            {
                $termSet.CustomSortOrder = $customSortOrder
            }
 
           $termSet.IsAvailableForTagging = [bool]::Parse($termSetNode.Attribute("IsAvailableForTagging").Value);
           $termSet.IsOpenForTermCreation = [bool]::Parse($termSetNode.Attribute("IsOpenForTermCreation").Value);
 
            if($termSetNode.Element("CustomProperties") -ne $null)
            {
                foreach($custProp in $termSetNode.Element("CustomProperties").Elements("CustomProperty"))
                {
                   $termSet.SetCustomProperty($custProp.Attribute("Key").Value, $custProp.Attribute("Value").Value)
                }
            }
  
           try
            {
                $Context.ExecuteQuery();
            }
            catch
            {
                Write-host "Error occured while create Term Set" $name $_.Exception.Message -ForegroundColor Red
                $errorOccurred = $true
            }
  
            write-host "created" -ForegroundColor Green
        }
        else {
            write-host "Already exists" -ForegroundColor Yellow
        }
             
  
        if(!$errorOccurred)
        {
            if ($termSetNode.Element("Terms") -ne $null)
            {
              foreach ($termNode in $termSetNode.Element("Terms").Elements("Term"))
               {
                  Create-Term $termNode $null $termSet $termStore $termStore.DefaultLanguage $Context
               }
            }    
        }                        
    }
}