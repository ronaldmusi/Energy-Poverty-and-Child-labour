******************************************************* Energy Poverty and Child Labour*********************************************************


clear all

*Setting up the working directory
cd "C:\Users\musizvingoza\OneDrive - United Nations University\Manuscripts\Child Labour\Energy Poverty\Raw Datasets\SPSS"
* Alternative directory (commented out)
**# Bookmark #1
 cd "C:\Users\user\OneDrive - United Nations University\Manuscripts\Child Labour\Energy Poverty\Raw Datasets\SPSS"
 
 cd "D:\Energy Poverty\Raw Datasets\SPSS"

* Adding numeric labels to data
numlabel, add



* Import SPSS datasets into STATA for a 64-bit version of Stata
* Install the usespss command from the beta repository
*net from http://radyakin.org/transfer/usespss/beta


// Define a list of countries
local countries benin car chad comoros drcongo eswatini ghana guinea lesotho madagascar malawi nigeria sao_tome siera_leonne thegambia togo zimbabwe

// Loop over each country
foreach country in `countries' {
    // Import the household members dataset from SPSS
    usespss "`country'_hl.sav", clear
	*import spss "`country'_hl.sav", clear
    sort HH1 HH2
    duplicates report HH1 HH2
    if r(N) > 0 {
        display "Duplicates detected in `country'_hl.dta for HH1 HH2"
        // Remove duplicates if necessary
        duplicates drop HH1 HH2, force
    }
    save "`country'_hl.dta", replace

    // Import the household dataset from SPSS
    usespss "`country'_hh.sav", clear
	*import spss "`country'_hh.sav", clear
    sort HH1 HH2
    duplicates report HH1 HH2
    if r(N) > 0 {
        display "Duplicates detected in `country'_hh.dta for HH1 HH2"
        // Remove duplicates if necessary
        duplicates drop HH1 HH2, force
    }
    save "`country'_hh.dta", replace

    // Import the child dataset from SPSS
    usespss "`country'_fs.sav", clear
	*import spss "`country'_fs.sav", clear
    sort HH1 HH2
    duplicates report HH1 HH2
    if r(N) > 0 {
        display "Duplicates detected in `country'_fs.dta for HH1 HH2"
        // Remove duplicates if necessary
        duplicates drop HH1 HH2, force
    }
    save "`country'_fs.dta", replace

    // Merge household dataset with household members dataset
    use "`country'_hl.dta", clear
    merge 1:1 HH1 HH2 using "`country'_hh.dta", keepusing(*)
    drop _merge
    save "`country'.dta", replace

    // Merge child dataset with the combined dataset
    merge 1:1 HH1 HH2 using "`country'_fs.dta", keepusing(*)
    drop _merge

    // Generate the weighted tabulation
    ta HH6 [iweight=fsweight]

    // Save the final merged dataset
    save "`country'_final.dta", replace
}
	
	local countries "benin car comoros drcongo eswatini ghana guinea lesotho madagascar malawi nigeria sao_tome siera_leonne thegambia togo zimbabwe"
	//Generate additional variables
foreach country in `countries' {	
	
    gen `country'_residence = HH6
    gen `country'_child_age = CB3
    gen `country'_child_sex = HL4
    gen `country'_cfundis = fsdisability
    gen `country'_child_edu = fselevel
    gen `country'_wealth_qunt = windex5
    gen `country'_hh_sex = HHSEX
    
    // Recode child age into age groups
    recode `country'_child_age (5/9 = 1 "5-9") (10/14 = 2 "10-14") (15/17=3 "15-17"), gen(`country'_age_group)
    tab `country'_age_group [iweight=fsweight]

    // PART A: Generating child labour variable using hours spent on economic activities in the past week: fs_CL3
    replace CL3 = 0 if CL3 == .
    gen `country'_eco_child_lab = 0
    replace `country'_eco_child_lab = 1 if CB3 < 12 & CL3 >= 1
    replace `country'_eco_child_lab = 1 if CB3 == 12 & CL3 >= 14
    replace `country'_eco_child_lab = 1 if CB3 == 13 & CL3 >= 14
    replace `country'_eco_child_lab = 1 if CB3 == 14 & CL3 >= 14
    replace `country'_eco_child_lab = 1 if CB3 == 15 & CL3 >= 43
    replace `country'_eco_child_lab = 1 if CB3 == 17 & CL3 >= 43
    lab var `country'_eco_child_lab "1=Economic child_labour"
    label define `country'_eco_child_lab 0 "No Child Labour" 1 "Eco Child Labour"
    label value `country'_eco_child_lab `country'_eco_child_lab
    tab `country'_eco_child_lab [iweight=fsweight]

    // PART B.1: Generating child labour variable based on hours spent on household chores in the past week: fs_CL13
    replace CL13 = 0 if CL13 == .
    gen `country'_hh_child_lab1 = 0
    replace `country'_hh_child_lab1 = 1 if CB3 < 18 & CL13 >= 21
    lab var `country'_hh_child_lab1 "1=household child_labour"
    label define `country'_hh_child_lab1 0 "No Child Labour" 1 "HH Child Labour"
    label value `country'_hh_child_lab1 `country'_hh_child_lab1
    tab `country'_hh_child_lab1 [iweight=fsweight]

    // PART C: Generate a variable for Child labour based hazardous work using variables for hazardous activities
    gen `country'_hazardous = 0
    replace `country'_hazardous = 1 if CL4 == 1 
    replace `country'_hazardous = 1 if CL5 == 1
    replace `country'_hazardous = 1 if CL6A == 1
    replace `country'_hazardous = 1 if CL6B == 1 
    replace `country'_hazardous = 1 if CL6C == 1 
    replace `country'_hazardous = 1 if CL6D == 1
    replace `country'_hazardous = 1 if CL6E == 1 
    replace `country'_hazardous = 1 if CL6X == 1 
    lab var `country'_hazardous "1=hazardous child labour"
    label define `country'_hazardous 0 "No Child Labour" 1 "Hazardous Child Labour"
    label value `country'_hazardous `country'_hazardous
    tab `country'_hazardous [iweight=fsweight]

    // PART D: Creating overall child labour variable using economic, household and hazardous work variables
    gen `country'_child_lab = 0
    replace `country'_child_lab = 1 if `country'_hh_child_lab1 == 1 
    replace `country'_child_lab = 1 if `country'_eco_child_lab == 1 
    replace `country'_child_lab = 1 if `country'_hazardous == 1 
    lab var `country'_child_lab "1= Total child_labour"
    label define `country'_child_lab 0 "No Child Labour" 1 "Total Child Labour"
    label value `country'_child_lab `country'_child_lab
    tab `country'_child_lab [iweight=fsweight]
 
}

/*Energy poverty (Multidimensional Energy Poverty Index)

Access to electricity (=1 if household has no access to electricity)
Cooking fuel (=1 if household uses other cooking fuels beside electricity, LPG, natural gas, or biogas)
Communication means (=1 if household does not own a mobile phone or landline)
Ownership of household appliances (=1 if household has no fridge)
Ownership of an entertainment appliance (=1 if household does not own a TV or radio)
*/
****************************
///TEMPORARY REMOVE THESE COUNTRIES SINCE THEY DONT HAVE STANDARD VARIABLES, 
**without HC9H-CHAD, GHANA
** WITHOUT HC9G-guinea, madagascar, malawi, siera_leonne thegambia 
**WITHOUT EUI-LESOTHO
*/

***********************************************
***********************************************
local countries "benin car comoros drcongo eswatini nigeria sao_tome togo zimbabwe"

foreach country in `countries' {
    use "`country'_vars.dta", clear

    // Generate variables related to energy poverty
    gen `country'_no_electricity = 1
    replace `country'_no_electricity = 0 if HC8 == 1 | HC8 == 2

    gen `country'_poor_cooking_fuel = 1
    replace `country'_poor_cooking_fuel = 0 if inlist(EU1, 1, 3, 4, 5)

    gen `country'_no_communication = 1
    replace `country'_no_communication = 0 if HC7A == 1 | HC12 == 1

    gen `country'_no_appliances = 1
    replace `country'_no_appliances = 0 if HC9B == 1 | HC9G == 1 | HC9H == 1

    gen `country'_no_entertainment = 1
    replace `country'_no_entertainment = 0 if HC9A == 1 | HC7B == 1

    // Derive the Multidimensional Energy Poverty Index (MEPI)
    // Note: The 'mpi' command is not a default Stata command and requires a user-written package.
    // Please ensure the 'mpi' package is installed before running this code.
    mpi d1(`country'_poor_cooking_fuel) d2(`country'_no_electricity) ///
        d3(`country'_no_appliances) d4(`country'_no_entertainment) ///
        d5(`country'_no_communication) w1(0.4) w2(0.2) w3(0.13) ///
        w4(0.13) w5(0.13), cutoff(0.5) depriveddummy(`country'_MEPI_dummy) ///
        deprivedscore(`country'_MEPI_total_score)

    // Rename the MEPI variables
    rename `country'_MEPI_dummy `country'_MEPI_dummy
    rename `country'_MEPI_total_score `country'_MEPI_total_score

    // Tabulate the MEPI dummy variable
    tab `country'_MEPI_dummy [iweight=fsweight]

    // Save the dataset with MEPI variables
    save "`country'_analysis.dta", replace
}

 

local countries "benin car comoros drcongo eswatini nigeria sao_tome togo zimbabwe"

foreach country in `countries' {
    

    // Load the main dataset for each country
    use "`country'_analysis.dta", clear

    // Keep specified variables
    keep HH1 HH2 LN FS1 FS2 FS3 fshweight fsweight hhweight `country'_child_sex `country'_child_age `country'_age_group `country'_cfundis  ///
               `country'_residence `country'_child_edu `country'_hh_sex `country'_wealth_qunt ///
			   `country'_eco_child_lab  `country'_hh_child_lab1 `country'_hazardous `country'_child_lab ///
			   `country'_no_electricity  `country'_poor_cooking_fuel `country'_no_communication `country'_no_appliances `country'_no_entertainment ///
			   `country'_MEPI_dummy  `country'_MEPI_total_score 
			   
    // Save the new dataset with the specified variables for each country
    save "`country'_new_dataset.dta", replace

}
local countries "benin car comoros drcongo eswatini nigeria sao_tome togo zimbabwe"
local first_country = "benin" // Assuming benin is the first dataset to start with

// Use the first country's dataset as the base
use "`first_country'_new_dataset.dta", clear

// Loop through the rest of the countries and append their datasets
foreach country in `countries' {
    if "`country'" != "`first_country'" {
        append using "`country'_new_dataset.dta"
    }
}

use "zimbabwe_new_dataset.dta", clear


// Generate the weighted tabulation for sex
// Define the list of variables for which to calculate frequency tables
local vars "zimbabwe_residence zimbabwe_child_age zimbabwe_child_sex zimbabwe_cfundis zimbabwe_child_edu zimbabwe_wealth_qunt zimbabwe_hh_sex zimbabwe_age_group"

// Loop through each variable and calculate the frequency table using fsweight
foreach var in `vars' {
    // Display the variable name
    di "Frequency table for `var'"
    
    // Calculate the frequency table
    tabulate `var' [iw=fsweight], missing
}














// Save the appended dataset
save "appended_dataset.dta", replace


//calculate frquencies


// Save the appended dataset
save "appended_dataset.dta", replace

local countries "benin car comoros drcongo eswatini nigeria sao_tome togo zimbabwe"

foreach country in `countries' {
    // Calculate frequencies
    mean(`country'_child_age)[iweight=fsweight]
    ta `country'_child_sex[iweight=fsweight]
    ta `country'_age_group[iweight=fsweight]
    ta `country'_cfundis[iweight=fsweight]
    ta `country'_child_edu[iweight=fsweight]
    ta `country'_wealth_qunt[iweight=fsweight]
	ta `country'_residence[iweight=fsweight]
    ta `country'_hh_sex[iweight=fsweight]
    ta `country'_eco_child_lab[iweight=fsweight]
    ta `country'_hh_child_lab1[iweight=fsweight]
    ta `country'_hazardous[iweight=fsweight]
    ta `country'_child_lab[iweight=fsweight]
    ta `country'_hazardous[iweight=fsweight]
    mean `country'_MEPI_total_score[iweight=fsweight]
    ta `country'_MEPI_dummy[iweight=fsweight]
	
	// Cross-tabulations with percentages
    tab `country'_child_sex `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_age_group `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_cfundis `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_child_edu `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_wealth_qunt `country'_MEPI_dummy[iweight=fsweight], row
	ta `country'_residence `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_hh_sex `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_eco_child_lab `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_hh_child_lab1 `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_hazardous `country'_MEPI_dummy[iweight=fsweight], row
    tab `country'_child_lab `country'_MEPI_dummy[iweight=fsweight], row
	
	
	// Cross-tabulations of child labour with percentages
    tab `country'_child_sex `country'_child_lab[iweight=fsweight], row
    tab `country'_age_group `country'_child_lab[iweight=fsweight], row
    tab `country'_cfundis `country'_child_lab[iweight=fsweight], row
    tab `country'_child_edu `country'_child_lab[iweight=fsweight], row
    tab `country'_wealth_qunt `country'_child_lab[iweight=fsweight], row
	ta `country'_residence `country'_child_lab[iweight=fsweight], row
    tab `country'_hh_sex `country'_child_lab[iweight=fsweight], row
	
	// Cross-tabulations of hh child labour with percentages
	 tab `country'_child_sex `country'_hh_child_lab1[iweight=fsweight], row
    tab `country'_age_group `country'_hh_child_lab1[iweight=fsweight], row
    tab `country'_cfundis `country'_hh_child_lab1[iweight=fsweight], row
    tab `country'_child_edu `country'_hh_child_lab1[iweight=fsweight], row
    tab `country'_wealth_qunt `country'_hh_child_lab1[iweight=fsweight], row
	ta `country'_residence `country'_hh_child_lab1[iweight=fsweight], row
    tab `country'_hh_sex `country'_hh_child_lab1[iweight=fsweight], row
	
	
	// Cross-tabulations of economuic child labour with percentages
    tab `country'_child_sex `country'_eco_child_lab[iweight=fsweight], row
    tab `country'_age_group `country'_eco_child_lab[iweight=fsweight], row
    tab `country'_cfundis `country'_eco_child_lab[iweight=fsweight], row
    tab `country'_child_edu `country'_eco_child_lab[iweight=fsweight], row
    tab `country'_wealth_qunt `country'_eco_child_lab[iweight=fsweight], row
	ta `country'_residence `country'_eco_child_lab[iweight=fsweight], row
    tab `country'_hh_sex `country'_eco_child_lab[iweight=fsweight], row
	
	
	// Cross-tabulations of hazardous work with percentages
    tab `country'_child_sex `country'_hazardous[iweight=fsweight], row
    tab `country'_age_group `country'_hazardous[iweight=fsweight], row
    tab `country'_cfundis `country'_hazardous[iweight=fsweight], row
    tab `country'_child_edu `country'_hazardous[iweight=fsweight], row
    tab `country'_wealth_qunt `country'_hazardous[iweight=fsweight], row
	ta `country'_residence `country'_hazardous[iweight=fsweight], row
    tab `country'_hh_sex `country'_hazardous[iweight=fsweight], row
	
	
	
	
}
	
	
// Save the appended dataset
save "appended_dataset.dta", replace

local countries "zimbabwe togo"

foreach country in `countries' {
    // Calculate frequencies
    mean(`country'_child_age)[iweight=fsweight]
    ta `country'_child_sex[iweight=fsweight]
    ta `country'_age_group[iweight=fsweight]
    ta `country'_cfundis[iweight=fsweight]
    ta `country'_child_edu[iweight=fsweight]
    ta `country'_wealth_qunt[iweight=fsweight]
    ta `country'_hh_sex[iweight=fsweight]
    ta `country'_eco_child_lab[iweight=fsweight]
    ta `country'_hh_child_lab1[iweight=fsweight]
    ta `country'_hazardous[iweight=fsweight]
    ta `country'_child_lab[iweight=fsweight]
    ta `country'_hazardous[iweight=fsweight]
    mean `country'_MEPI_total_score[iweight=fsweight]
    ta `country'_MEPI_dummy[iweight=fsweight]

    // Cross-tabulations with child_lab in the columns
    tab `country'_MEPI_dummy `country'_child_sex[iweight=fsweight], col
    estout, cells("col") replace
    tab `country'_MEPI_dummy `country'_age_group[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_cfundis[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_child_edu[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_wealth_qunt[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_hh_sex[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_eco_child_lab[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_hh_child_lab1[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_hazardous[iweight=fsweight], col
    estout, cells("col") append
    tab `country'_MEPI_dummy `country'_child_lab[iweight=fsweight], col
    estout, cells("col") append
}



// Load the dataset
use "appended_dataset.dta", clear

// Define the list of countries
local countries "benin car comoros drcongo eswatini nigeria sao_tome togo zimbabwe"

// Initialize the country code number
local num 1

// Define the standard variable names without the country prefix
local vars "residence child_age child_sex cfundis child_edu wealth_qunt hh_sex age_group eco_child_lab hh_child_lab1 hazardous child_lab no_electricity poor_cooking_fuel no_communication no_appliances no_entertainment MEPI_dummy MEPI_total_score"

// Loop through each country's dataset
foreach country in `countries' {
    // Use the dataset and rename variables by dropping the country prefix
    use "`country'_new_dataset.dta", clear
    foreach var in `vars' {
        local oldname `country'_`var'
        local newname `var'
        capture rename `oldname' `newname'
    }
    
    // If it's the first country, create the country code and ID variables
    if "`country'" == "benin" {
        gen country_code = `num'
        gen id = string(country_code) + "_" + string(HH1) + "_" + string(HH2)
        save "appended_dataset_with_codes_and_ids.dta", replace
    }
    else {
        // For subsequent countries, append to the base dataset
        local ++num
        append using "appended_dataset_with_codes_and_ids.dta"
        replace country_code = `num' if country_code == .
        replace id = string(country_code) + "_" + string(HH1) + "_" + string(HH2) if id == ""
        save "appended_dataset_with_codes_and_ids.dta", replace
    }
}






// The final dataset with standardized variable names and unique identifiers is saved

// Define the local vars
local vars "residence child_age child_sex cfundis child_edu wealth_qunt hh_sex age_group"

// Start the Word document
putdocx begin

// Loop through each variable and output the frequency table to the Word document
foreach var in `vars' {
    // Display the variable name in the console
    di "Frequency table for `var'"
    
    // Insert a title for the table in the Word document
    putdocx paragraph, style(Heading 1) text("Frequency table for `var'")
    
    // Calculate the frequency table and store the results
    quietly tabulate `var' [iw=fsweight], missing matcell(f_`var') matrow(r_`var')
    
    // Output the frequency table to the Word document
    putdocx table, matrix(f_`var') rowlabels(r_`var')
}

// Save the Word document
putdocx save "Frequency_Tables.docx", replace

// End the Word document
putdocx end



// Generate the weighted tabulation for sex
// Define the list of variables for which to calculate frequency tables
local vars "residence child_age child_sex cfundis child_edu wealth_qunt hh_sex age_group"

// Loop through each variable and calculate the frequency table using fsweight
foreach var in `vars' {
    // Display the variable name
    di "Frequency table for `var'"
    
    // Calculate the frequency table
    tabulate `var' [iw=fsweight], missing
}

///child labour variables 

local vars "eco_child_lab hh_child_lab1 hazardous child_lab"

// Loop through each variable and calculate the frequency table using fsweight
foreach var in `vars' {
    // Display the variable name
    di "Frequency table for `var'"
    
    // Calculate the frequency table
    tabulate `var' [iw=fsweight], missing
}

///energy poverty
local vars "no_electricity poor_cooking_fuel no_communication no_appliances no_entertainment MEPI_dummy"

// Loop through each variable and calculate the frequency table using fsweight
foreach var in `vars' {
    // Display the variable name
    di "Frequency table for `var'"
    
    // Calculate the frequency table
    tabulate `var' [iw=fsweight], missing
}

summarize MEPI_total_score

save "final_analysis.dta", replace






















