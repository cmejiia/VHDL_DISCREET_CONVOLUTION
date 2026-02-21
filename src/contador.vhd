library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity contador is
    generic (
        NBITS : integer := 11    -- Numero de bits para almacenar el contador 11@2k y 13@8k
    );
    port (
        clk: in std_ulogic;
        rst: in std_ulogic;
        rst_sinc: in std_ulogic;
        ena: in std_ulogic;
        Q:   out unsigned(NBITS-1 downto 0)  
    );
end contador;

architecture contador_arch of contador is

    signal cont, p_cont: unsigned(NBITS-1 downto 0);

begin

    comb: process(ena, cont)
    begin
        if  ena = '1' then
            p_cont <= cont + 1;
        else
            p_cont <= cont;
        end if;
    end process;

    sync: process(rst, clk)
    begin
        if rst = '1' then
            cont <= (others => '0');
        elsif rising_edge(clk) then
            if rst_sinc = '1' then
                cont <= (others => '0');
            else
                cont <= p_cont;
            end if;
        end if;
    end process;

    Q <= cont;

end contador_arch;