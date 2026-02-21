-- @author Hipólito Guzmán-Miranda
-- This code infers a BRAM when synthesized.
-- ``addri`` has been defined as ``unsigned`` for convenience, but could also be defined as ``std_logic_vector`` if needed
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram is
  generic (
    DATA_WIDTH : integer := 8;  -- Width of the data bus
    ADDR_WIDTH : integer := 8   -- Width of the address bus
    );
  port (clk   : in  std_logic;                                 -- Clock signal, active on rising edge
        addri : in  unsigned (ADDR_WIDTH-1 downto 0);          -- Address
        datai : in  std_logic_vector (DATA_WIDTH-1 downto 0);  -- Input data
        we    : in  std_logic;                                 -- Write enable
        datao : out std_logic_vector (DATA_WIDTH-1 downto 0)   -- Output data
        );
end bram;

architecture bram_arch of bram is

  type ram_type is array ((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);  -- Data type for memory contents
  signal ram : ram_type;  -- Memory contents

begin

  -- When synthesizing this process, the synthesizer infers a BRAM 
  process(clk)
  begin
    if (rising_edge(clk)) then
      if (we = '1') then
        ram(to_integer(addri)) <= datai;
      end if;
      datao <= ram(to_integer(addri));
    end if;
  end process;

end bram_arch;
