/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package rbsa.eoss;

/**
 *
 * @author Marc
 */
import java.io.BufferedReader;
import java.io.InputStreamReader;
import rbsa.eoss.local.Params;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Random;

public class ArchitectureGenerator {

    private static ArchitectureGenerator instance = null;
    private ArrayList<Architecture> population;
    private Random rnd;
    
    private ArchitectureGenerator() {
        rnd = new Random();
    }

    public static ArchitectureGenerator getInstance() {
        if (instance == null) {
            instance = new ArchitectureGenerator();
        }
        return instance;
    }

    public ArrayList<Architecture> generatePrecomputedPopulation() {
        long NUM_ARCHS = Params.norb * Math.round(Math.pow(2, Params.ninstr) - 1);
        population = new ArrayList((int) NUM_ARCHS);
        try {
            for (int ns=0;ns<Params.nsats.length;ns++){
                for (int o = 0; o < Params.norb; o++) {
                    for (int ii = 1; ii < Math.round(Math.pow(2, Params.ninstr)); ii++) {
                        boolean[][] mat = new boolean[Params.norb][Params.ninstr];
                        boolean[] bin = de2bi(ii,Params.ninstr);
                        for (int i = 0; i < Params.norb; i++) {
                            if (o == i) {
                                for (int j = 0; j < Params.ninstr; j++) {
                                    if (bin[j]) {
                                        mat[i][j] = true;
                                    } else {
                                        mat[i][j] = false;
                                    }
                                }
                            } else {
                                for (int j = 0; j < Params.ninstr; j++) {
                                    mat[i][j] = false;
                                }
                            }   
                        }
                        population.add(new Architecture(mat,Params.nsats[ns]));
                    }
                }
        }

        } catch (Exception e) {
            System.out.println(e.getMessage());
        }

        return (ArrayList<Architecture>) population;
    }
    public static boolean[] de2bi(int d, int N) {
        boolean[] b = new boolean[N];
        for (int i = 0;i<N;i++) {
            //double q = (double)d/2;
            int r = d%2;
            if (r == 1) {
                b[i] = true;
            } else {
                b[i] = false;
            }
            d = d/2;
        }
        return b;
    }
    public ArrayList<Architecture> getInitialPopulation (int NUM_ARCHS) {
        if (Params.initial_pop.isEmpty())
            return generateRandomPopulation(NUM_ARCHS);
        else
            return ResultManager.getInstance().loadResultCollectionFromFile(Params.initial_pop).getPopulation();
    }
    
    public ArrayList<Architecture> generateRandomPopulation(int NUM_ARCHS) {
        //int NUM_ARCHS = 100;
        int GENOME_LENGTH = Params.ninstr * Params.norb;
        population = new ArrayList(NUM_ARCHS);
        Random rnd = new Random();
        try {
            for (int i = 0; i < NUM_ARCHS; i++) {
                boolean[] x = new boolean[GENOME_LENGTH];
                for (int j = 0; j < GENOME_LENGTH; j++) {
                    x[j] = rnd.nextBoolean();
                }
                Architecture arch = new Architecture(x, Params.norb, Params.ninstr,Params.nsats[rnd.nextInt(Params.nsats.length)]);
                //arch.setEval_mode("DEBUG");
                population.add(arch);
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }

        return (ArrayList<Architecture>) population;
    }

    public ArrayList<Architecture> localSearch(ArrayList<Architecture> pop0) {
        //Remove duplicates
        
        ArrayList<Architecture> pop1 = new ArrayList<Architecture>(); 
        for (int i = 0;i<pop0.size()-1;i++) {
            Architecture arch1 = pop0.get(i);
            boolean UNIQUE = true;
            for (int j = i+1;j<pop0.size();j++) {
                Architecture arch2 = pop0.get(j);
                if (!arch1.getId().equalsIgnoreCase(arch2.getId()) && arch1.compareTo(arch2) == 0) {
                    //System.out.println("Eliminating duplicate a1 = " + arch1.getId() + " " + arch1.toString() + " a2 = " + arch2.getId() + " " + arch2.toString());
                    UNIQUE = false;
                    break;
                }
            }
            if (UNIQUE)
                pop1.add(arch1);
        }
        //ArrayList<Architecture> pop1  = new ArrayList<Architecture>(new HashSet<Architecture>(pop0));
        int n1 = pop1.size();
        ArrayList<Architecture> pop2  = new ArrayList<Architecture>();
        int nvars = pop1.get(0).getBitString().length;
        for (Architecture arch:pop1) {
            Architecture newarch;
            if (arch.getNsats()>1) {
                newarch = new Architecture(arch.getBitString(),Params.norb,Params.ninstr,arch.getNsats()-1);
                newarch.setEval_mode("DEBUG");
                pop2.add(newarch);
            }
            if (arch.getNsats()<Params.nsats[Params.nsats.length-1]) {
                newarch = new Architecture(arch.getBitString(),Params.norb,Params.ninstr,arch.getNsats()+1);
                newarch.setEval_mode("DEBUG");
                pop2.add(newarch);
            }
        }
        for (int k = 0;k<n1;k++) {
            //System.out.println("Searching around arch " + k);
            for (int j = 0;j<nvars;j++) {
                boolean[] arch = pop1.get(k).getBitString().clone();
                if(arch[j]) {
                    arch[j] = false;
                } else {
                    arch[j] = true;
                }
                Architecture new_one = new Architecture(arch,Params.norb,Params.ninstr,pop1.get(k).getNsats());
                new_one.setEval_mode("DEBUG");
                pop2.add(new_one);
            }
        }
        
        //Remove duplicates after local search
        ArrayList<Architecture> pop3 = new ArrayList<Architecture>(); 
        for (Architecture arch1:pop2) {
            boolean UNIQUE = true;
            for (Architecture arch2:pop2) {
                if (!arch1.getId().equalsIgnoreCase(arch2.getId()) && arch1.compareTo(arch2) == 0) {
                    UNIQUE = false;
                    break;
                }
            }
            if (UNIQUE)
                pop3.add(arch1);
        }
        return pop3;
    }
    
    public ArrayList<Architecture> getPopulation() {
        return population;
    }

    //Single architecture constructors
    public Architecture getRandomArch() {
        boolean[][] mat = new boolean[Params.norb][Params.ninstr];
        for (int i = 0; i < Params.norb; i++) {
            for (int j = 0;j < Params.ninstr;j++) {
                mat[i][j] = rnd.nextBoolean();
            }

        }
        return new Architecture(mat,Params.nsats[rnd.nextInt(Params.nsats.length)]);
    }
    public Architecture getTestArch() { // SMAP 2 SSO orbits, 2 sats per orbit
        Architecture arch = new Architecture("0011000000111110000000000",1);
        arch.setEval_mode("DEBUG");
        return arch;//{"SMAP_RAD","SMAP_MWR","CMIS","VIIRS","BIOMASS"};{"600polar","600AM","600DD","800AM","800PM"};
    }

    public Architecture getMaxArch() {
        boolean[][] mat = new boolean[Params.norb][Params.ninstr];
        for (int i = 0; i < Params.norb; i++) {
            for (int j = 0;j < Params.ninstr;j++) {
                mat[i][j] = true;
            }

        }
        return new Architecture(mat,2);
    }
    public Architecture getMinArch() {
        boolean[][] mat = new boolean[Params.norb][Params.ninstr];
        for (int i = 0; i < Params.norb; i++) {
            for (int j = 0;j < Params.ninstr;j++) {
                mat[i][j] = false;
            }

        }
        return new Architecture(mat,1);
    }
    public Architecture getUserEnteredArch() { // This architecture has a science score of 0.02
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
        
        HashMap<String,String[]> mapping= new HashMap<String,String[]>();
        for (String orb:Params.orbit_list) {    
            try {
                boolean valid = false;
                String input = "";
                while(!valid) {
                    System.out.println("New payload in " + orb + "? ");
                    input = bufferedReader.readLine();
                    String[] instruments = input.split(" ");
                    ArrayList<String> validInstruments = new ArrayList<String>();
                    validInstruments.addAll(Arrays.asList(Params.instrument_list));
                    valid = true;
                    for (int i = 0;i<instruments.length;i++) {
                        String instr= instruments[i];
                        if(instr.equalsIgnoreCase("")) {
                            valid = true;
                            break;
                        }
                        if(!validInstruments.contains(instr)) {
                            valid = false;
                            break;
                        }
                    }
                }    
                mapping.put(orb,input.split(" "));
            } catch (Exception e) {
                System.out.println("EXC in getUserEnteredArch" + e.getMessage() + " " + e.getClass());
                e.printStackTrace();
                return null;
            }           
        }
        System.out.println("Num sats per orbit? " );
        try{
            String tmp = bufferedReader.readLine();
            return new Architecture(mapping,Integer.parseInt(tmp));
        }catch(Exception e){
            System.out.println("EXC in getUserEnteredArch" + e.getMessage() + " " + e.getClass());
            e.printStackTrace();
            return null;
        }
        
    }
    public void setPopulation(ArrayList<Architecture> population) {
        this.population = population;
    }
}
