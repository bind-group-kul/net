// test2.cpp : Defines the entry point for the console application.
//

#include <fstream>
#include <iostream>
#include <string>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <cstdlib>
#include <iomanip>
#include <cmath>
#include <ctime>

#include "nr3.h"
#include "mex.h"

//-------------- TYPEDEF'S --------------//
typedef struct {
   int t[3];
   double N[3];
} TLIST;

typedef struct {
   double v[3];
   double N[3];
   double nor;
   int idx;
   int edge;
} VLIST;

typedef struct {
   int nver, ntri;
   TLIST *T;
   VLIST *V;
   //double Tr[16];
} MODEL;

template<class T>
inline std::string to_string(const T& t)
{
	std::stringstream ss;
	ss << t;
	return ss.str();
}

//-------------- CLASS DEFINITIONS --------------//
class BioCalc_HeadModelFileReader
{
private:
	unsigned int			Size;
	NRvector<double>		Buffer;
	bool					Init;
	char				    FileName[80];
	std::fstream*			FileHandle;

public:
	BioCalc_HeadModelFileReader();
	BioCalc_HeadModelFileReader(const char*);	
	~BioCalc_HeadModelFileReader();
	int IsInitialized();			//checks of instance is initialized
	double read();				//reads 1 object of type double
	NRvector<double> read(int);				//reads n consecutive objects of type double
	NRvector<double> read(long n);  //funcion sobrecargada para leer n valores con long definition
	NRvector<long> readL(long n);  //funcion sobrecargada para leer long values!!!
	int open(const char *);
	long FileSize();
	char *getFileName();
	bool EndOfFile();
	friend std::istream& operator>>(std::istream& , BioCalc_HeadModelFileReader& );
};


class BioCalc_HeadModel
{
public:
	//label for different tissues
	enum TISSUE { AIR=0, SCALP=1, SKULL=2, CSF=3, BRAIN=4, GRAYMATTER=4, WHITEMATTER=5};
	BioCalc_HeadModel(void);
	BioCalc_HeadModel(std::string path, std::string filename, int S[3], double V[3]);
	BioCalc_HeadModel(std::string, std::string);
	~BioCalc_HeadModel(void);
	int ReadHeadModel(std::string);
	int ReadFullModel(std::string);
	int ReadModelHDR(std::string fname, long Nelem, long Nnzeros);
	std::string getpath();
	std::string getFileName();
	int getDimX();
	int getDimY();
	int getDimZ();
	NRvector<int> getSize();
	int getSize(int);
	double getVoxelSizeX();
	double getVoxelSizeY();
	double getVoxelSizeZ();
	NRvector<double> getVoxelSize();
	long getHeadModelXYZ(int,int,int);
    NRvector<double> getConductivityXYZ(int,int,int);
    double getConductivityXYZ(int,int,int,int);
	long getnumelements();
	long getnonzeros();
	//int getnumelectrodes();
	bool CheckSurrounded(int,int,int);
	std::string getModelID();
	void SetConstraint(enum TISSUE);

private:
	NRvector<int>			Size;
	NRMat3d<int>			HeadModel;
	NRMat4d<double> 		Conductivity;
	NRvector<double>		VoxelSize;
	long					nonzeros;
	long					numelements;
	std::string				directory;  
	std::string				modelnr;
	int						constraint;
};


class BioCalc_MGMRESSolver
{
public:
	BioCalc_MGMRESSolver(void);
	~BioCalc_MGMRESSolver(void);
	void InitializeNR(BioCalc_HeadModel * hmodel, std::string pwrite);
	
private:	
	// Main Functions //
	void WriteCidxNR(std::string filename);
	void WriteBinAIJ_NR(std::string Aname, NRvector<double> A, std::string Iname, NRvector<int> I, std::string Jname, NRvector<int> J);
	void WriteBinAIJ_V(std::string Aname, std::vector<double> A, std::string Iname, std::vector<int> I, std::string Jname, std::vector<int> J, long nonz);
	void SetSolveNR(BioCalc_HeadModel* H, std::string pwrite);
	void SetRDX_NR(int r, int c, double val, long &idx, NRvector<double> &A, NRvector<int> &I, NRvector<int> &J);
	void SetRDX_V(int r, int c, double val, long &idx, std::vector<double> A, std::vector<int> I, std::vector<int> J);

public:
	NRvector<double>  A_s;
	NRvector<int>     IA_s, JA_s;
	NRMat3d<long>     c_idx;	
	long nonz;

private:
	NRMat3d<double>   cf_a, cf_b, cf_c, cf_d, cf_e, cf_f, cf_g;
	NRmatrix<int>     co_l, rn_z;
	NRvector<double>  L_s, re_s;
	NRvector<int>     UA_s;
	NRmatrix<double>  stiff_m;
	double omega, tole;
	int itermx, itrmtx;
	int   iterations, nonzeros, itr_mgmres;
	double eps;
	long nno, nnz,nord;
};


//-------------- GLOBAL VARIABLES --------------//
std::string path;
std::string model;
int     Size[3];
double  VoxelSize[3];
long    NoElements;
long    NoNonZeros;
int     NoElectrodes;
int     NoLeads;
clock_t t_ini, t_fin;
MODEL srcs;
BioCalc_HeadModel    *hmodel;
BioCalc_MGMRESSolver *solver;


//-------------- FUNCTION PROTOTYPES --------------//
void headr(void);
void ReadP(std::string fname);
void WriteStiffnessMatrix(std::string pwrite);

//--- BioCalc_Tools ---//
long getfilesize(const char*);

NRvector<int> ind2sub(NRvector<int>,int);
int sub2ind(NRvector<int>,NRvector<int>);
long sub2indL(NRvector<int> siz,NRvector<int> subs);
long sub2indL(NRvector<int> siz, int sub0, int sub1, int sub2);
long sub2indL0(NRvector<int> siz, int sub0, int sub1, int sub2);


//-------------- MEX FUNCTION --------------//
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    char *input_buf, *input_buf_w;
	//std::string input_buf, input_buf_w;
    size_t buflen, buflen_w;

	unsigned char *start_of_pr;
    size_t bytes_to_copy;
    
    /* check for proper number of arguments */
    if(nrhs!=2) 
      mexErrMsgIdAndTxt( "MATLAB:revord:invalidNumInputs",
              "Two input required.");
    else if(nlhs != 4) 
      mexErrMsgIdAndTxt( "MATLAB:revord:maxlhs",
              "Four output required.");

    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1 || mxIsChar(prhs[1]) != 1 )
      mexErrMsgIdAndTxt( "MATLAB:revord:inputNotString",
              "Input must be a string.");

    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1)
      mexErrMsgIdAndTxt( "MATLAB:revord:inputNotVector",
              "Input must be a row vector.");
    
    /* get the length of the input string */
    buflen   = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;
	buflen_w = (mxGetM(prhs[1]) * mxGetN(prhs[1])) + 1;

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    input_buf   = mxArrayToString(prhs[0]);
	input_buf_w = mxArrayToString(prhs[1]);
    
    if(input_buf == NULL || input_buf_w == NULL ) 
      mexErrMsgIdAndTxt( "MATLAB:revord:conversionFailed",
              "Could not convert input to string.");
    
    /* call the C subroutine */
    //revord(input_buf, buflen, output_buf);

    /* set C-style string output_buf to MATLAB mexFunction output*/
	mexPrintf("The read string is: %s\n", input_buf);
	mexPrintf("The write string is: %s\n", input_buf_w);

	char* pEnd;
	int initlead = 0;
	int lead = 1;

	model = "head_model";
	std::string pread  = input_buf;  //= "AFDRM/DOS";
	std::string pwrite = input_buf_w; //= "AFDRM/DOS";

	path = pread + "/";
	std::string filename_P = path + model + "_P.txt";	
	
	ReadP(filename_P); 
	hmodel = new BioCalc_HeadModel(pread, model, Size, VoxelSize);
	solver = new BioCalc_MGMRESSolver(); 
	WriteStiffnessMatrix(pwrite); //*/

	mexPrintf("nonz: %i\n", (int)solver->nonz);

	long lsa = solver->A_s.size();
	long lsb = solver->IA_s.size();
	long lsc = solver->JA_s.size();

	int dim[3];
	dim[0] = solver->c_idx.dim1();
	dim[1] = solver->c_idx.dim2();
	dim[2] = solver->c_idx.dim3();//*/

	long lsd = dim[0]*dim[1]*dim[2];
	NRvector<long> out_d(lsd);
	long cnt_i = 0;
	for(int k=0;k<dim[2];k++)
		for(int j=0;j<dim[1];j++)
			for(int i=0;i<dim[0];i++){					
				out_d[cnt_i] = solver->c_idx[i][j][k];
				cnt_i++;
			}
	
    //plhs[0] = mxCreateString(output_buf);
	plhs[0]    = mxCreateNumericMatrix(lsa,1,mxDOUBLE_CLASS,mxREAL);
	start_of_pr = (unsigned char *)mxGetData(plhs[0]);
    bytes_to_copy = lsa * mxGetElementSize(plhs[0]);
	memcpy(start_of_pr, solver->A_s.v, bytes_to_copy);

	plhs[1]    = mxCreateNumericMatrix(lsb,1,mxINT32_CLASS,mxREAL);
	start_of_pr = (unsigned char *)mxGetData(plhs[1]);
    bytes_to_copy = lsb * mxGetElementSize(plhs[1]);
	memcpy(start_of_pr, solver->IA_s.v, bytes_to_copy);

	plhs[2]    = mxCreateNumericMatrix(lsc,1,mxINT32_CLASS,mxREAL);
	start_of_pr = (unsigned char *)mxGetData(plhs[2]);
    bytes_to_copy = lsc * mxGetElementSize(plhs[2]);
	memcpy(start_of_pr, solver->JA_s.v, bytes_to_copy);

	plhs[3]    = mxCreateNumericMatrix(lsd,1,mxINT64_CLASS,mxREAL);
	start_of_pr = (unsigned char *)mxGetData(plhs[3]);
    bytes_to_copy = lsd * mxGetElementSize(plhs[3]);
	memcpy(start_of_pr, out_d.v, bytes_to_copy);

	delete hmodel;
	delete solver;
    mxFree(input_buf);
	mxFree(input_buf_w);
    return;
}


//-------------- FUNCTIONS --------------//
void headr(void)
{
	//cout << "FDM solver..." << endl;
	mexPrintf("Ernesto Cuartas Morales 2020\n");
	mexPrintf("ecuartasm@gmail.com\n");
	mexPrintf("Building AFDM Stiffnes Matrix...\n");
}

void ReadP(std::string fname)
{		
	char* pEnd;
	std::string parameter, value, tmp, val2, val3;
	std::ifstream inSettings(fname.c_str());
	if (!inSettings)
	{
		mexPrintf("Settings could not be opened.\n");
		exit(1);
	}
	while (!inSettings.eof()){
		inSettings >> parameter >> value;
		tmp=parameter.c_str();
		if (tmp=="Size:")			  
		{
			inSettings >> val2 >> val3;
			Size[0] = (int)strtod(value.c_str(),&pEnd);
			Size[1] = (int)strtod(val2.c_str(),&pEnd);
			Size[2] = (int)strtod(val3.c_str(),&pEnd);		    
		}
		if (tmp=="VoxelSize:")			
		{
			inSettings >> val2 >> val3;
			VoxelSize[0] = (double)strtod(value.c_str(),&pEnd);
			VoxelSize[1] = (double)strtod(val2.c_str(),&pEnd);
			VoxelSize[2] = (double)strtod(val3.c_str(),&pEnd);
		}
		if (tmp=="NoElements:")
			NoElements   = (long)strtod(value.c_str(),&pEnd);
		if (tmp=="NoNonZeros:")
			NoNonZeros   = (long)strtod(value.c_str(),&pEnd);
	}

	mexPrintf("size: %i  %i  %i\n", Size[0], Size[1], Size[2]);
	mexPrintf("VoxelSize: %f  %f  %f\n", (float)VoxelSize[0], (float)VoxelSize[1], (float)VoxelSize[2]);
	mexPrintf("NoElements: %i\n", (int)NoElements);
	mexPrintf("NoNonZeros: %i\n", (int)NoNonZeros);
	inSettings.close();
}

void WriteStiffnessMatrix(std::string pwrite)
{
	std::string hdmodel = path + model + ".hdr";
	//std::cout << "hdmodel: " << hdmodel << std::endl;	

	t_ini = clock();
	hmodel->ReadModelHDR(hdmodel.c_str(), NoElements, NoNonZeros);
	solver->InitializeNR(hmodel,pwrite);
	t_fin = clock();
    double secs = (double)(t_fin - t_ini) / CLOCKS_PER_SEC;	
	mexPrintf("Time: %f\n", (float)secs);	
}//*/


//-------------------------------------------------------//
//-------------------- BioCalc_Tools --------------------//
//-------------------------------------------------------//
long getfilesize(const char * file)
{
	std::fstream fileh;
	fileh.open(file);
	if (!fileh){
		mexPrintf("error reading leadfield indices\n");
		return 0;
	}
	std::fstream::pos_type current_pos = fileh.tellg();
	fileh.seekg(0,std::ios_base::beg);
	std::fstream::pos_type begin_pos = fileh.tellg();
	fileh.seekg(0, std::ios_base::end);
	std::fstream::pos_type end_pos = fileh.tellg();
	fileh.seekg(current_pos);
	return static_cast<long>(end_pos - begin_pos);
	fileh.close();
}

NRvector<int> ind2sub(NRvector<int> siz,int ndx)
{
	int t;
	NRvector<int> k(siz.size());
		for (int i=0;i<k.size();i++)
		{
			int cumprod=1;
			for (int j=0;j<i;j++)
			{
				cumprod*=siz[j];
			}
			k[i]=cumprod;
		}

	NRvector<int> subs(3);

	for (int j=siz.size();j>0;j--)
	{
		t=(ndx-1)%k[j-1]+1;
		subs[j-1]=(ndx - t)/(k[j-1])+1;
		ndx=t;
	}
	return subs;
}

int sub2ind(NRvector<int> siz,NRvector<int> subs)
{
	int t;
	NRvector<int> k(siz.size());
	for (int i=0;i<k.size();i++)
	{
		int cumprod=1;
		for (int j=0;j<i;j++)
		{
			cumprod*=siz[j];
		}
		k[i]=cumprod;
	}
	t=1;
	for (int i=0;i<k.size();i++)
	{
		t+=(subs[i]-1)*k[i];
	}
	return t;
}

long sub2indL(NRvector<int> siz,NRvector<int> subs)
{
	long t;
	NRvector<long> k(siz.size());
	for (long i=0;i<k.size();i++)
	{
		long cumprod=1;
		for (long j=0;j<i;j++)
		{
			cumprod*=siz[j];
		}
		k[i]=cumprod;
	}
	t=1;
	for (long i=0;i<k.size();i++)
	{
		t+=(subs[i]-1)*k[i];
	}
	return t;
}

long sub2indL(NRvector<int> siz, int sub0, int sub1, int sub2)
{
	return( sub0 + siz[0]*sub1 + sub2*siz[0]*siz[1] + 1 );
}

long sub2indL0(NRvector<int> siz, int sub0, int sub1, int sub2)
{
	return( sub0 + siz[0]*sub1 + sub2*siz[0]*siz[1] );
	//long ret =  sub0 + siz[0]*sub1 + sub2*siz[0]*siz[1];
//	return ret;
}



//---------------------------------------------------------------------//
//-------------------- BioCalc_HeadModelFileReader --------------------//
//---------------------------------------------------------------------//
BioCalc_HeadModelFileReader::BioCalc_HeadModelFileReader()
{
		Init = 0;
		FileHandle = NULL;
}

BioCalc_HeadModelFileReader::BioCalc_HeadModelFileReader(const char* fname): Init(0)
{
	if (Init==1) {
		FileHandle->close();
		Init=0;
	}
	FileHandle = new std::fstream(fname,std::ios::binary | std::ios::in);
	//FileHandle->open(fname,ios::binary | ios::in);
	if (!FileHandle->is_open()) {
		std::cerr << "Failure opening filename :" << fname << "!";
		exit(1);
	}
	else { 
		Init = 1;
		strcpy(FileName,fname);
	}
}

BioCalc_HeadModelFileReader::~BioCalc_HeadModelFileReader()
{
	delete FileHandle;
}

int BioCalc_HeadModelFileReader::open(const char * fname)
{
	if (Init==1)
	{
		FileHandle->close();
		Init=0;
	}
	FileHandle = new std::fstream(fname,std::ios::binary | std::ios::in);
	//FileHandle->open(fname,ios::binary | ios::in);
	if (!FileHandle->is_open())
	{
		std::cerr << "Failure opening filename :" << fname << "!";
		return -1;
		exit(1);
	}else
	{ Init = 1;
	  strcpy(FileName,fname);
	  return 1;
	}

}

int BioCalc_HeadModelFileReader::IsInitialized()
{
	return Init;
}

double BioCalc_HeadModelFileReader::read()
{
	double buffer;
	FileHandle->read((char *)(&buffer),sizeof(double));
	return buffer;
}

NRvector<double> BioCalc_HeadModelFileReader::read(int n)
{
	NRvector<double> buffer(n);
	double tmp;
	for (int i=0;i<n;i++)
	{
		FileHandle->read((char *)(&tmp),sizeof(double));
		buffer[i]=(double)tmp;
	}
	//cout << buffer.size();
	//cout << buffer;
	return buffer;
}

NRvector<double> BioCalc_HeadModelFileReader::read(long n)
{
	NRvector<double> buffer(n);
	double tmp;
	for (long i=0;i<n;i++)
	{
		FileHandle->read((char *)(&tmp),sizeof(double));
		buffer[i]=(double)tmp;
	}
	return buffer;
}

NRvector<long> BioCalc_HeadModelFileReader::readL(long n)
{
	NRvector<long> buffer(n);
	long tmp;
	for (long i=0;i<n;i++)
	{
		FileHandle->read((char *)(&tmp),sizeof(long));
		buffer[i]=(long)tmp;
	}
	return buffer;
}


long BioCalc_HeadModelFileReader::FileSize()
{

	if (!FileHandle->good() || FileHandle->eof() || !FileHandle->is_open())
	{
		std::cerr << "No File was opened!" << std::endl;
		return 0;
	}else
	{
		std::fstream::pos_type current_pos = FileHandle->tellg();
		FileHandle->seekg(0,std::ios_base::beg);
		std::fstream::pos_type begin_pos = FileHandle->tellg();
		FileHandle->seekg(0, std::ios_base::end);
		std::fstream::pos_type end_pos = FileHandle->tellg();
		FileHandle->seekg(current_pos);
		//cout << current_pos << "  "  << FileHandle->tellg() << "   " << endl;
		return static_cast<long>(end_pos - begin_pos);
	}
}

std::istream& operator>>(std::istream& s, BioCalc_HeadModelFileReader& r)
{
	return s;

}

char * BioCalc_HeadModelFileReader::getFileName()
{
	return FileName;
}

bool BioCalc_HeadModelFileReader::EndOfFile()
{
	return FileHandle->eof();
}


//-----------------------------------------------------------//
//-------------------- BioCalc_HeadModel --------------------//
//-----------------------------------------------------------//
BioCalc_HeadModel::BioCalc_HeadModel(void) { }

BioCalc_HeadModel::~BioCalc_HeadModel(void) { 
	/*
	Size.~NRvector();
	HeadModel.~NRMat3d();
	Conductivity.~NRMat4d();
	VoxelSize.~NRvector();//*/
}

BioCalc_HeadModel::BioCalc_HeadModel(std::string path, std::string filename, int S[3], double V[3])
{
	this->directory = path + "/";
	this->modelnr = filename;

	Size.resize(3);
	Size[0] = S[0];
	Size[1] = S[1];
	Size[2] = S[2];
	
	this->VoxelSize.resize(3);
	this->VoxelSize[0] = V[0];
	this->VoxelSize[1] = V[1];
	this->VoxelSize[2] = V[2];

	HeadModel.resize(Size[0],Size[1],Size[2]);
}


std::string BioCalc_HeadModel::getpath()
{
	return directory;
}

std::string BioCalc_HeadModel::getFileName()
{
	return (this->directory + this->modelnr);
}


void BioCalc_HeadModel::SetConstraint(enum BioCalc_HeadModel::TISSUE T)
{
	constraint=T;
}

int BioCalc_HeadModel::ReadModelHDR(std::string fname, long Nelem, long Nnzeros)
{
	Conductivity.assign(Size[0],Size[1],Size[2],6, 0.0);
	BioCalc_HeadModelFileReader mod_reader; 
	mod_reader.open(fname.c_str());
	std::cout << "Reading file " << mod_reader.getFileName() << std::endl;
	// reading meta information and setting dimensions
	numelements = Nelem;
	std::cout << "Total number of elements : " << numelements << std::endl;
	std::cout << "Size of the file is : " << mod_reader.FileSize() <<  " Bytes" << std::endl;
	if(Nnzeros == mod_reader.FileSize()/10/sizeof(double))	
		nonzeros = Nnzeros;
	else	{
		std::cout << "File: " << mod_reader.getFileName() <<  " Is not a valid file, the data amount is wrong" << std::endl;
		return -1;
	}

	std::cout << "Number of nonzeros is " << nonzeros << std::endl;
	//setting up buffer and info to read labels and conductivity
	NRvector<double> buffer;
	int progress=0; //to monitor progress
	long count=0;  //to count nonzero elements
	int speedupfactor=100,subsx=0,subsy=0,subsz=0;
	double index=0.0;

	for(int i=0;i<nonzeros;i=i+speedupfactor)
	{
		if (i+speedupfactor>nonzeros)
			speedupfactor=nonzeros-i;

		buffer=mod_reader.read(speedupfactor*10);
		for(int j=0;j<speedupfactor;j++)
		{
			//index = buffer[0+(j)*10];
			subsx=(unsigned char)buffer[0+(j)*10];
			subsy=(unsigned char)buffer[1+(j)*10];
			subsz=(unsigned char)buffer[2+(j)*10];

			if ((HeadModel[subsx][subsy][subsz]=(unsigned char)buffer[3+(j)*10]))
			{
				this->Conductivity[subsx][subsy][subsz][0]=(double)buffer[4+(j)*10];
				this->Conductivity[subsx][subsy][subsz][1]=(double)buffer[5+(j)*10];
				this->Conductivity[subsx][subsy][subsz][2]=(double)buffer[6+(j)*10];
				this->Conductivity[subsx][subsy][subsz][3]=(double)buffer[7+(j)*10];
				this->Conductivity[subsx][subsy][subsz][4]=(double)buffer[8+(j)*10];
				this->Conductivity[subsx][subsy][subsz][5]=(double)buffer[9+(j)*10];
				//printf("Label %d %d %d %d %f %f %f %f %f %f\n",subsx-1,subsy-1,subsz-1,HeadModel[subsx-1][subsy-1][subsz-1],
				//		this->Conductivity[subsx-1][subsy-1][subsz-1][0],this->Conductivity[subsx-1][subsy-1][subsz-1][1],
				//		this->Conductivity[subsx-1][subsy-1][subsz-1][2],this->Conductivity[subsx-1][subsy-1][subsz-1][3],
				//		this->Conductivity[subsx-1][subsy-1][subsz-1][4],this->Conductivity[subsx-1][subsy-1][subsz-1][5]);
				count++;
			}

			//printf("Label %d %d %d %d\n",subsx-1,subsy-1,subsz-1,HeadModel[subsx-1][subsy-1][subsz-1]);
 		}
		if (((((double)i)/(double)nonzeros)*100)>progress) {
			std::cout << "Loading: " << std::setprecision(2) << std::setw(6) << int((double)i/(double)nonzeros*100) << " %\r" << std::flush;
			progress+=10;
			}
	}

	std::cout << std::setprecision(2) << std::setw(6) << "Loading: 100 %\r" << std::flush;
	std::cout << "\n" << std::endl;
	//mod_reader.~BioCalc_HeadModelFileReader();
	return 0;
}

int BioCalc_HeadModel::getDimX()
{
	return Size[0];
}

int BioCalc_HeadModel::getDimY()
{
	return Size[1];
}

int BioCalc_HeadModel::getDimZ()
{
	return Size[2];
}

NRvector<int> BioCalc_HeadModel::getSize()
{
	return Size;
}

long BioCalc_HeadModel::getHeadModelXYZ(int i,int j,int k)
{
	return HeadModel[i][j][k];
}

double BioCalc_HeadModel::getConductivityXYZ(int i,int j,int k,int l)
{
	return Conductivity[i][j][k][l];
}


long BioCalc_HeadModel::getnumelements()
{
	return numelements;
}


long BioCalc_HeadModel::getnonzeros()
{
	return nonzeros;
}

NRvector<double> BioCalc_HeadModel::getVoxelSize()
{
	return this->VoxelSize;
}

double BioCalc_HeadModel::getVoxelSizeX(){
	return this->VoxelSize[0];
}

double BioCalc_HeadModel::getVoxelSizeY(){
	return this->VoxelSize[1];
}

double BioCalc_HeadModel::getVoxelSizeZ(){
	return this->VoxelSize[2];
}

std::string BioCalc_HeadModel::getModelID(){
	return this->modelnr;
}


//--------------------------------------------------------------//
//-------------------- BioCalc_MGMRESSolver --------------------//
//--------------------------------------------------------------//
BioCalc_MGMRESSolver::BioCalc_MGMRESSolver(void)
{
	nonzeros = 0;
	tole = 1e-13;
	itermx = 10;
	itrmtx = 100;
}

BioCalc_MGMRESSolver::~BioCalc_MGMRESSolver(void)
{
	/*
	A_s.~NRvector();
	IA_s.~NRvector(); 
	JA_s.~NRvector();
	c_idx.~NRMat3d();
	cf_a.~NRMat3d();
	cf_b.~NRMat3d();
	cf_c.~NRMat3d();
	cf_d.~NRMat3d();
	cf_e.~NRMat3d();
	cf_f.~NRMat3d();
	cf_g.~NRMat3d();
	co_l.~NRmatrix();
	rn_z.~NRmatrix();
	L_s.~NRvector();
	re_s.~NRvector();
	UA_s.~NRvector();
	stiff_m.~NRmatrix();//*/
}

void BioCalc_MGMRESSolver::InitializeNR(BioCalc_HeadModel * hmodel, std::string pwrite)
{
	//HeadModel.resize(Size[0],Size[1],Size[2]);

	std::cout << "the headmodel file is " << hmodel->getFileName() << std::endl;
	std::cout << "Voxelsize is " << hmodel->getVoxelSize() << " mm." << std::endl;

	std::cout << "Defining tensor elements from Saleheen...";
	this->cf_a.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->cf_b.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->cf_c.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->cf_d.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->cf_e.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->cf_f.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->cf_g.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);
	this->c_idx.assign(hmodel->getDimX()+1,hmodel->getDimY()+1,hmodel->getDimZ()+1, 0.0);

	for(int i=1;i<hmodel->getDimX();i++)
		for(int j=1;j<hmodel->getDimY();j++)
			for(int k=1;k<hmodel->getDimZ();k++)
			{
				cf_a[i][j][k] = ( hmodel->getConductivityXYZ(i-1,j-1,k-1,0) + hmodel->getConductivityXYZ(i-1,j,k-1,0) +
								hmodel->getConductivityXYZ(i-1,j-1,k,0)   + hmodel->getConductivityXYZ(i-1,j,k,0) )     
								/ (4*hmodel->getVoxelSizeX()*hmodel->getVoxelSizeX());

				cf_b[i][j][k] = ( hmodel->getConductivityXYZ(i-1,j-1,k-1,1) + hmodel->getConductivityXYZ(i,j-1,k-1,1) +
								 hmodel->getConductivityXYZ(i-1,j-1,k,1)   + hmodel->getConductivityXYZ(i,j-1,k,1))     
								 / (4*hmodel->getVoxelSizeY()*hmodel->getVoxelSizeY());
						
				cf_c[i][j][k] = ( hmodel->getConductivityXYZ(i-1,j-1,k-1,2) + hmodel->getConductivityXYZ(i,j-1,k-1,2) +
								 hmodel->getConductivityXYZ(i-1,j,k-1,2)   + hmodel->getConductivityXYZ(i,j,k-1,2))
								 / (4*hmodel->getVoxelSizeZ()*hmodel->getVoxelSizeZ());

				cf_d[i][j][k] = ( hmodel->getConductivityXYZ(i-1,j-1,k-1,5) + hmodel->getConductivityXYZ(i,j-1,k-1,5)) /
							   (4*hmodel->getVoxelSizeY()*hmodel->getVoxelSizeZ());
						
				cf_e[i][j][k] = ( hmodel->getConductivityXYZ(i-1,j-1,k-1,4)+hmodel->getConductivityXYZ(i-1,j,k-1,4)) /
							   (4*hmodel->getVoxelSizeX()*hmodel->getVoxelSizeZ());
						
				cf_f[i][j][k] = ( hmodel->getConductivityXYZ(i-1,j-1,k-1,3)+hmodel->getConductivityXYZ(i-1,j-1,k,3)) /
			   				   (4*hmodel->getVoxelSizeX()*hmodel->getVoxelSizeY());

			}
	
	nonzeros = 0;

	double tmp;
			
	for(int k=1;k<hmodel->getDimZ();k++)
		for(int j=1;j<hmodel->getDimY();j++)
			for(int i=1;i<hmodel->getDimX();i++)			
				{
					cf_g[i][j][k] = - ( cf_a[i][j][k] + cf_a[i+1][j][k] + 
						                cf_b[i][j][k] + cf_b[i][j+1][k] + 
										cf_c[i][j][k] + cf_c[i][j][k+1] + 
										cf_d[i][j][k] - cf_d[i][j][k+1] + cf_d[i][j+1][k+1] - cf_d[i][j+1][k] + 
										cf_e[i][j][k] - cf_e[i+1][j][k] + cf_e[i+1][j][k+1] - cf_e[i][j][k+1] + 
										cf_f[i][j][k] - cf_f[i+1][j][k] + cf_f[i+1][j+1][k] - cf_f[i][j+1][k] );

					/*
					coefg(i,j,k) = - ( coefa(i,j,k) + coefa(i+1,j,k) +
									   coefb(i,j,k) + coefb(i,j+1,k) +
									   coefc(i,j,k) + coefc(i,j,k+1) +
									   coefd(i,j,k) - coefd(i,j,k+1) + coefd(i,j+1,k+1) - coefd(i,j+1,k) +
									   coefe(i,j,k) - coefe(i+1,j,k) + coefe(i+1,j,k+1) - coefe(i,j,k+1) +
									   coeff(i,j,k) - coeff(i+1,j,k) + coeff(i+1,j+1,k) - coeff(i,j+1,k) );//*/
					if( cf_g[i][j][k] != 0) 
					{
						nonzeros++;
						c_idx[i][j][k] = nonzeros;
					}
				}

	std::cout << "done!" << std::endl;
	SetSolveNR(hmodel, pwrite);
}

void BioCalc_MGMRESSolver::SetSolveNR(BioCalc_HeadModel* H, std::string pwrite)
{
	std::cout << "Setting sparce matrix values"  << std::endl;
	clock_t t1 = clock();
	double tiem;

	NRvector<int> sizefield(3);
	sizefield[0] = H->getDimX() + 1;
	sizefield[1] = H->getDimY() + 1;
	sizefield[2] = H->getDimZ() + 1;
	
	long row_idx, col_idx[19];
	double coef[19];
	long idx, row, coln;

	NRvector<int> sizearray(3);
	sizearray[0] = H->getDimX() - 1;
	sizearray[1] = H->getDimY() - 1;
	sizearray[2] = H->getDimZ() - 1;
	
	nonz = 19*nonzeros;

	/*
	double *Ax_v = new double[nonz];
	int    *Ix_v = new int[nonz];
	int    *Jx_v = new int[nonz];//*/

	/*
	std::vector<double> Ax_v(nonz, 0.0);
	std::vector<int>    Ix_v(nonz, 0.0);
	std::vector<int>    Jx_v(nonz, 0.0);//*/
	
	//Vtst.assign(nonz, 0.0);//*/		
	NRvector<double> A_nr(nonz, 0.0), Ax_nr(nonz, 0.0);
	NRvector<int>    JA_nr(nonz, 0.0), Jx_nr(nonz, 0.0), Ix_nr(nonz, 0.0);

	idx = 0;

	int mp = 0;

	//IAs.resize(nonzeros + 1);
	//IAs = 0;	

	for(int k=1; k<this->cf_g.dim3() - 1;k++) {			
		for(int j=1; j<this->cf_g.dim2() - 1;j++) {
			for(int i=1; i<this->cf_g.dim1() - 1;i++)
			{
				if( cf_g[i][j][k] )
				{									
					// A0
					col_idx[0] = c_idx[i][j][k];//cidx(i,j,k);
					row_idx    = c_idx[i][j][k]-1;//cidx(i,j,k)-1;


					// A2
					col_idx[2] = c_idx[i-1][j][k];//cidx(i-1,j,k);
					coef[2]    = cf_a[i][j][k];//coefa(i,j,k);
					// A1
					col_idx[1] = c_idx[i+1][j][k];//cidx(i+1,j,k);
					coef[1]    = cf_a[i+1][j][k];//coefa(i+1,j,k);


					// A3
					col_idx[3] = c_idx[i][j-1][k];//cidx(i,j-1,k);
					coef[3]    = cf_b[i][j][k];//coefb(i,j,k);
					// A4
					col_idx[4] = c_idx[i][j+1][k];//cidx(i,j+1,k);
					coef[4]    = cf_b[i][j+1][k];//coefb(i,j+1,k);


					// A6
					col_idx[6] = c_idx[i][j][k-1];//cidx(i,j,k-1);
					coef[6]    = cf_c[i][j][k];//coefc(i,j,k);
					// A5
					col_idx[5] = c_idx[i][j][k+1];//cidx(i,j,k+1);
					coef[5]    = cf_c[i][j][k+1];//coefc(i,j,k+1);
							

					// A18
					col_idx[18] = c_idx[i][j+1][k+1];//cidx(i,j+1,k+1);
					coef[18]    = cf_d[i][j+1][k+1];//coefd(i,j+1,k+1);
					// A17
					col_idx[17] =   c_idx[i][j+1][k-1];//cidx(i,j+1,k-1);
					coef[17]    = - cf_d[i][j+1][k];//coefd(i,j+1,k);
					// A16
					col_idx[16] = c_idx[i][j-1][k-1];//cidx(i,j-1,k-1);
					coef[16]    = cf_d[i][j][k];//coefd(i,j,k);
					// A15
					col_idx[15] =   c_idx[i][j-1][k+1];//cidx(i,j-1,k+1);
					coef[15]    = - cf_d[i][j][k+1];//coefd(i,j,k+1);


					// A11
					col_idx[11] =   c_idx[i-1][j][k+1];//cidx(i-1,j,k+1);
					coef[11]    = - cf_e[i][j][k+1];//coefe(i,j,k+1);
					// A14 
					col_idx[14] = c_idx[i+1][j][k+1];//cidx(i+1,j,k+1);
					coef[14]    = cf_e[i+1][j][k+1];//coefe(i+1,j,k+1);
					// A13
					col_idx[13] =   c_idx[i+1][j][k-1];//cidx(i+1,j,k-1);
					coef[13]    = - cf_e[i+1][j][k];//coefe(i+1,j,k);
					// A12
					col_idx[12] = c_idx[i-1][j][k-1];//cidx(i-1,j,k-1);
					coef[12]    = cf_e[i][j][k];//coefe(i,j,k);
				

					// A8
					col_idx[8] =   c_idx[i-1][j+1][k];//cidx(i-1,j+1,k);
					coef[8]    = - cf_f[i][j+1][k];//coeff(i,j+1,k);
					// A9
					col_idx[9] = c_idx[i+1][j+1][k];//cidx(i+1,j+1,k);
					coef[9]    = cf_f[i+1][j+1][k];//coeff(i+1,j+1,k);
					// A10
					col_idx[10] =   c_idx[i+1][j-1][k];//cidx(i+1,j-1,k);
					coef[10]    = - cf_f[i+1][j][k];//coeff(i+1,j,k);
					// A7
					col_idx[7] = c_idx[i-1][j-1][k];//cidx(i-1,j-1,k);
					coef[7]    = cf_f[i][j][k];//coeff(i,j,k);

					//////////////   Set val   ///////////////

					// diag
					SetRDX_NR(row_idx, c_idx[i][j][k]-1, cf_g[i][j][k], idx, Ax_nr, Ix_nr, Jx_nr);
					//SetRDX_V(row_idx, c_idx[i][j][k]-1, cf_g[i][j][k], idx, Ax_v, Ix_v, Jx_v);

					// off diag 
					for(int a=1; a<=18; a++) {
						if(col_idx[a] > row_idx)
							//SetRDX_V(row_idx, col_idx[a]-1, coef[a], idx, Ax_v, Ix_v, Jx_v);						
							SetRDX_NR(row_idx, col_idx[a]-1, coef[a], idx, Ax_nr, Ix_nr, Jx_nr);						
					}
				}		
			}
			//std::cout << "j: " << j << std::endl;
		}			
		//std::cout << "k: " << k << std::endl;
	}
	nonz = idx;

	A_s.assign(nonz, 0.0);
	JA_s.assign(nonz, 0);
	IA_s.assign(nonz, 0);//*/

	nno = nonzeros;
	nnz = nonz;
	
	for(long k = 0; k<nonz; k++){
		A_s[k]  = Ax_nr[k];
		JA_s[k] = Jx_nr[k];
		IA_s[k] = Ix_nr[k];
	}//*/

	//WriteBinAIJ_NR(pwrite + "/A_bin.bin", A_s, pwrite + "/I_bin.bin", IA_s, pwrite + "/J_bin.bin", JA_s);
	//WriteCidxNR(pwrite + "/cidx.bin");
}

void BioCalc_MGMRESSolver::WriteCidxNR(std::string filename)
{
	std::ofstream fieldfile(filename, std::ios::out | std::ios::binary);
		long tmp;
		for(int k=0;k<c_idx.dim3();k++)
			for(int j=0;j<c_idx.dim2();j++)
				for(int i=0;i<c_idx.dim1();i++)
				{					
  						tmp = c_idx[i][j][k];					
						fieldfile.write((char *) &tmp,sizeof(long));
				}
	 fieldfile.close();
	 std::cout << "Data file cidx written : " << filename << std::endl;
}

void BioCalc_MGMRESSolver::WriteBinAIJ_NR(std::string Aname, NRvector<double> A, std::string Iname, NRvector<int> I, std::string Jname, NRvector<int> J)
{
	std::ofstream fieldfile1(Aname, std::ios::out | std::ios::binary);
	double tmp1;

	for(int i=0;i<A.size();i++)
	{					
  		tmp1 = A[i];		
		fieldfile1.write((char *) &tmp1,sizeof(double));
	}
	fieldfile1.close();
	std::cout << "Data file A_bin written : " << Aname << std::endl;

		
	std::ofstream fieldfile2(Iname, std::ios::out | std::ios::binary);
	int tmp2;
	for(int i=0;i<I.size();i++)
	{					
  		tmp2 = I[i];
		fieldfile2.write((char *) &tmp2,sizeof(int));
	}
	fieldfile2.close();
	std::cout << "Data file I_bin written : " << Iname << std::endl;

		
	std::ofstream fieldfile3(Jname, std::ios::out | std::ios::binary);
	int tmp3;
	for(int i=0;i<J.size();i++)
	{					
  		tmp3 = J[i];
		fieldfile3.write((char *) &tmp3,sizeof(int));
	}
	fieldfile3.close();
	std::cout << "Data file J_bin written : " << Jname << std::endl;
}

void BioCalc_MGMRESSolver::WriteBinAIJ_V(std::string Aname, std::vector<double> A, std::string Iname, std::vector<int> I, std::string Jname, std::vector<int> J, long nonz)
{
	std::ofstream fieldfile1(Aname, std::ios::out | std::ios::binary);
	double tmp1;

	for(long i=0;i<nonz;i++)
	{					
  		tmp1 = A[i];		
		fieldfile1.write((char *) &tmp1,sizeof(double));
	}
	fieldfile1.close();
	std::cout << "Data file A_bin written : " << Aname << std::endl;

		
	std::ofstream fieldfile2(Iname, std::ios::out | std::ios::binary);
	int tmp2;
	for(long i=0;i<nonz;i++)
	{					
  		tmp2 = I[i];
		fieldfile2.write((char *) &tmp2,sizeof(int));
	}
	fieldfile2.close();
	std::cout << "Data file I_bin written : " << Iname << std::endl;

		
	std::ofstream fieldfile3(Jname, std::ios::out | std::ios::binary);
	int tmp3;
	for(long i=0;i<nonz;i++)
	{					
  		tmp3 = J[i];
		fieldfile3.write((char *) &tmp3,sizeof(int));
	}
	fieldfile3.close();
	std::cout << "Data file J_bin written : " << Jname << std::endl;
}

void BioCalc_MGMRESSolver::SetRDX_NR(int r, int c, double val, long &idx, NRvector<double> &A, NRvector<int> &I, NRvector<int> &J)
{
	if(r == c)	{
		A[idx]  = val;
		J[idx] = c;
		I[idx] = r;
		idx++;
	}
	else  {
		A[idx]  = val;
		J[idx] = c;
		I[idx] = r;
		idx++;

		A[idx]  = val;
		J[idx] = r;
		I[idx] = c;
		idx++;
	}
}

void BioCalc_MGMRESSolver::SetRDX_V(int r, int c, double val, long &idx, std::vector<double> A, std::vector<int> I, std::vector<int> J)
{
	if(r == c)	{
		A[idx]  = val;
		J[idx] = c;
		I[idx] = r;
		idx++;
	}
	else  {
		A[idx]  = val;
		J[idx] = c;
		I[idx] = r;
		idx++;

		A[idx]  = val;
		J[idx] = r;
		I[idx] = c;
		idx++;
	}
}
