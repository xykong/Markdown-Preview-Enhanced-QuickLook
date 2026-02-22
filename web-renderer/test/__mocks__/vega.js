const mockView = {
    toSVG: jest.fn().mockResolvedValue('<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>'),
};
const View = jest.fn().mockImplementation(() => mockView);
const parse = jest.fn().mockReturnValue({});
module.exports = { View, parse };
