import pandas as pd 
import numpy as np
import glob, os

#Setting paths
projpath = os.path.realpath("..")
pathibd  = os.path.join(projpath, "Results", "RefinedIBD")
#Move directory
os.chdir(pathibd)

#Entering all folders in RefinedIBD results
dirs = os.listdir()
for di in dirs:
    if os.path.isdir(os.path.join(pathibd, di)):
        os.chdir(os.path.join(pathibd, di))
        #First, generate a list of all unique IDs
        ID_list = pd.Series(dtype=str)
        filenames = glob.glob("*.ibd")
        for file in filenames:
            ID_read1 = pd.Series(pd.read_csv(file, sep="\t", names=["ID"], usecols=[0], dtype={"ID":str})["ID"].unique()) #Getting first column of IBD file
            ID_read2 = pd.Series(pd.read_csv(file, sep="\t", names=["ID"], usecols=[2], dtype={"ID":str})["ID"].unique()) #Getting second column of IBD file
            ID_list = ID_list.append(ID_read1, ignore_index=True) #Appending values to IBD list
            ID_list = ID_list.append(ID_read2, ignore_index=True) #Appending values to IBD list

        ID_list = ID_list.unique() #Removing duplicates

        #Second, create an empty matrix to add values after
        size         = len(ID_list) #size of matrix
        empty_matrix = np.zeros((size, size))
        ibd_matrix   = pd.DataFrame(empty_matrix, columns=ID_list, index=ID_list)

        #Third, reading each line one at a time and adding the cm value to the corresponding cells
        for file in glob.glob("*.ibd"):
            with open(file) as f:
                for line in f:
                    id1 = line.split("\t")[0]
                    id2 = line.split("\t")[2]
                    cm  = line.split("\t")[8].strip()
                    #Adding values to both sides of the matrix
                    ibd_matrix.at[ id1, id2 ] += float(cm)
                    ibd_matrix.at[ id2, id1 ] += float(cm)

        ibd_matrix.to_csv("cMmatrix.txt")