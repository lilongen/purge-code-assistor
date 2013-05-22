#!/bin/bash
#



# int
# int[]
# int []
# Vector<int>
# Vector <int>
# Vector < int >
# Vector<int>[]
# Vector<int> []
# Vector<int[]> []
# Vector<int [] > []
DataTypeRe='\w+\s*(<\s*[\w]+\s*(\[\])?\s*>)?\s*(\[\])?'

# ()
# (type1 var1
# (type1 var1, type2 var2
# (type1 var1, type2 var2, type3 var3
# (type1<type2> var1, type2<type3>[] var2, type3 var3
FunctionParameterRe="($DataTypeRe|\,|\s)*"

#public ClassName(
#public ClassName(int a)
ConstructorRe="^\s*(private|public|protected)\s+\w+\($FunctionParameterRe"

#public void send(MailVO mail) throws WbxMailProcessorException {
#void setTemplateValues(String emailAddress, Map info);
#public static String encodeTag(String value) {
FunctionDeclareRe="^\s*(private |public |protected )?[\w\s]*$DataTypeRe(?<!return|new)\s+\w+\($FunctionParameterRe"

#void setTemplateValues(String emailAddress, Map info);
InterfaceFunctionRe="^\s*$DataTypeRe\s+\w+\($FunctionParameterRe"

PurgedPackage="$1"
PurgedPackageLocation="$2"
CpaMiddleFileLocation=".cpa/$PurgedPackage"

PURGED_SELF_CLASSES_FILE="$CpaMiddleFileLocation/inner.classes"
SELF_CLASSES_METHODS_FILE="$CpaMiddleFileLocation/self.classes.methods"
echo "" > $SELF_CLASSES_METHODS_FILE
while read line; do
	echo "$line" >> $SELF_CLASSES_METHODS_FILE
	grep -o -P "$ConstructorRe" "$line" >> $SELF_CLASSES_METHODS_FILE
	grep -o -P "$FunctionDeclareRe" "$line" >> $SELF_CLASSES_METHODS_FILE
	
	interfacePatternMatch=$(grep -o -P '^\s*public interface \w+\s*' "$line")
	if [ ${#interfacePatternMatch} -gt 0 ];then
		grep -o -P "$InterfaceFunctionRe" "$line" >> $SELF_CLASSES_METHODS_FILE
	fi
	echo -e "\n" >> $SELF_CLASSES_METHODS_FILE
done < $PURGED_SELF_CLASSES_FILE
